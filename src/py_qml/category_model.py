import logging

from PySide6.QtCore import (
    Property,
    QAbstractListModel,
    QByteArray,
    QModelIndex,
    QObject,
    Qt,
    Signal,
    Slot,
)
from PySide6.QtQml import QmlElement
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from data import db
from data.models import MonthlyTransaction, Transaction, TransactionCategory, TransactionType
from py_qml.common import EmptyStringError, OperationResult, strip_name

QML_IMPORT_NAME = "PFM.Models"
QML_IMPORT_MAJOR_VERSION = 1

# Create logger for context
logger = logging.getLogger(__name__)


@QmlElement
class CategoryModel(QAbstractListModel):
    display_for_changed = Signal()

    def _get_current_display_for(self) -> str:
        return self._display_for.value

    def _set_current_display_for(self, value: str) -> None:
        # Try to convert given string to enum value
        try:
            new_type = TransactionType(value.lower())

            if self._display_for != new_type:
                self._display_for = new_type

                self.beginResetModel()
                self._categories = self._get_categories()
                self.endResetModel()

                self.display_for_changed.emit()
        except ValueError:
            logger.exception("Failed to set display_for value: %s", value)

    display_for = Property(  # signifies what categories to display based on transaction type
        str,
        _get_current_display_for,
        _set_current_display_for,
        notify=display_for_changed,  # type: ignore  # noqa: PGH003
    )

    def _get_categories(self) -> list[str]:
        """Get the categories for the current display type."""
        with db.create_session() as session:
            # Create query statement
            stmt = select(TransactionCategory).where(
                TransactionCategory.transaction_type == self._display_for,
            )

            # Execute query
            categories = [category.name for category in session.scalars(stmt).all()]

        # Append creation element to categories
        categories.append("Create new category")

        return categories

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._display_for = TransactionType.EXPENSE
        self._categories = self._get_categories()

    def rowCount(self, parent: QModelIndex = QModelIndex()) -> int:  # noqa: ARG002, B008, N802
        """Return the number of rows in the model."""
        return len(self._categories)

    def data(self, index: QModelIndex, role: int = Qt.ItemDataRole.DisplayRole) -> str | None:
        """Return the data for a given row in the model."""
        row = index.row()

        if index.isValid() and row < self.rowCount() and role == Qt.ItemDataRole.DisplayRole:
            return self._categories[row]

        return None

    def roleNames(self) -> dict[int, QByteArray]:  # noqa: N802
        """Return the role names for QML."""
        return {Qt.ItemDataRole.DisplayRole: QByteArray(b"name")}

    @Slot(str, result=int)
    def get_index(self, category_name: str) -> int:
        """Get the index of a category in the model."""
        try:
            return self._categories.index(category_name)
        except ValueError:
            return -1

    @Slot()
    def update_model(self) -> None:
        """Update the model to reflect current categories in the db."""
        self.beginResetModel()
        self._categories = self._get_categories()
        self.endResetModel()

    @Slot(str, result=dict)
    def append(self, category_name: str) -> OperationResult:
        """Create a new category for current transaction_type and append it to data model and db."""
        try:
            category_name = strip_name(category_name, "Category name cannot be blank.")

            with db.create_session() as session:
                # Add new category to the database
                new_category = TransactionCategory(
                    name=category_name,
                    transaction_type=self._display_for,
                )

                # Gather data for logging
                new_category_info = (
                    f"Name: {new_category.name}, Type: {new_category.transaction_type.value}"
                )

                session.add(new_category)
                session.commit()

            # Log new category creation
            logger.info("Created new category: %s", new_category_info)

            # Append new category to the model
            self.beginInsertRows(QModelIndex(), 0, 0)  # Insert at the front
            self._categories.insert(0, category_name)  # Insert at the front of the list
            self.endInsertRows()

        except IntegrityError:  # Catch duplicate names
            return {"success": False, "error": "A category with that name already exists."}
        except EmptyStringError as err:
            return {"success": False, "error": str(err)}
        except Exception:
            logger.exception("Failed to add new category")
            return {"success": False, "error": "An unexpected error occurred."}
        else:
            return {"success": True}

    @Slot(str, str, result=dict)
    def edit(self, category_name: str, new_name: str) -> OperationResult:
        """Change an existing category's name in the data model and db."""
        try:
            new_name = strip_name(new_name, "New category name cannot be blank.")

            with db.create_session() as session:
                stmt = select(TransactionCategory).where(TransactionCategory.name == category_name)

                to_edit = session.scalars(stmt).one()

                to_edit.name = new_name

                category_type = to_edit.transaction_type.value

                session.commit()

            # Log category edit
            logger.info(
                "Edited %s category: From '%s' to '%s'",
                category_type,
                category_name,
                new_name,
            )

            # Check if data model needs to be updated
            if self.display_for == category_type:
                index = self._categories.index(category_name)

                # Update the model
                self._categories[index] = new_name
                model_index = self.index(index, 0)  # Qt method that returns a QModelIndex
                self.dataChanged.emit(model_index, model_index)

        except IntegrityError:  # Catch duplicate names
            return {"success": False, "error": "A category with that name already exists."}
        except EmptyStringError as err:
            return {"success": False, "error": str(err)}
        except Exception:
            logger.exception("Failed to edit new category")
            return {"success": False, "error": "An unexpected error occurred."}
        else:
            return {"success": True}

    @Slot(int, result=bool)
    def remove(self, index: int) -> bool:
        """Remove a category from the data model and db.

        Returns true if successful, false otherwise.
        """
        try:
            category_name = self._categories[index]

            with db.create_session() as session:
                # Get the category to remove
                stmt = select(TransactionCategory).where(
                    TransactionCategory.name == category_name,
                )

                to_remove = session.scalars(stmt).one()

                # Store category type for later use
                category_type = to_remove.transaction_type.value

                # Gather data for logging
                transaction_stmt = select(Transaction).where(
                    Transaction.category == category_name,
                )

                monthly_stmt = select(MonthlyTransaction).where(
                    MonthlyTransaction.category == category_name,
                )

                removed_category_info = (
                    f"Category: {to_remove.name}, Type: {to_remove.transaction_type.value}"
                )

                transactions_deleted_info = [
                    f"Id {transaction.id}, "
                    f"Name: {transaction.name}, Amount: {transaction.amount}, "
                    f"Type: {transaction.transaction_type.value}, "
                    f"Date: {transaction.execution_date}, Category: {transaction.category}"
                    for transaction in session.scalars(transaction_stmt).all()
                ]

                monthly_transactions_deleted_info = [
                    f"Id {monthly_transaction.id}, "
                    f"Name: {monthly_transaction.name}, Amount: {monthly_transaction.amount}, "
                    f"Type: {monthly_transaction.transaction_type.value}, "
                    f"Day of Month: {monthly_transaction.day_of_month}, "
                    f"Category: {monthly_transaction.category}, "
                    f"Start Date: {monthly_transaction.start_date}, "
                    f"End Date: {monthly_transaction.end_date or 'None'}"
                    for monthly_transaction in session.scalars(monthly_stmt).all()
                ]

                # Delete category
                session.delete(to_remove)
                session.commit()

            # Log category removal
            logger.info(
                "Deleted category: %s, with %i transactions and %i monthly transactions",
                removed_category_info,
                len(transactions_deleted_info),
                len(monthly_transactions_deleted_info),
            )

            for transaction_info in transactions_deleted_info:
                logger.info(
                    "Deleted transaction: %s",
                    transaction_info,
                )

            for monthly_transaction_info in monthly_transactions_deleted_info:
                logger.info(
                    "Deleted monthly transaction: %s",
                    monthly_transaction_info,
                )

            # Check if the model needs to be updated
            if self.display_for == category_type:
                # Remove the category from the model
                self.beginRemoveRows(QModelIndex(), index, index)
                self._categories.pop(index)
                self.endRemoveRows()

        except IndexError:
            logger.exception("Index out of range")
            return False
        except Exception:
            logger.exception("Failed to remove category")
            return False
        else:
            return True
