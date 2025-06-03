import datetime
import logging
from dataclasses import dataclass
from datetime import date
from decimal import Decimal
from enum import IntEnum
from typing import cast

from PySide6.QtCore import (
    Property,
    QAbstractListModel,
    QByteArray,
    QDate,
    QEnum,
    QModelIndex,
    QObject,
    Qt,
    Signal,
    Slot,
)
from PySide6.QtQml import QmlElement
from sqlalchemy import select

from data import db, models
from data.models import TransactionType
from py_qml.common import EmptyStringError, OperationResult, strip_name

QML_IMPORT_NAME = "PFM.Models"
QML_IMPORT_MAJOR_VERSION = 1

# Create logger for context
logger = logging.getLogger(__name__)


@QmlElement
class TransactionModel(QAbstractListModel):
    current_month_changed = Signal()

    def _get_current_month(self) -> QDate:
        """Get the current month (qml side)."""
        current_month = self._current_month
        return QDate(current_month.year, current_month.month, current_month.day)

    current_month = Property(QDate, _get_current_month, notify=current_month_changed)  # type: ignore  # noqa: PGH003

    @Slot()
    def next_month(self) -> None:
        """Move to the next month."""
        year = self._current_month.year + (1 if self._current_month.month == 12 else 0)  # noqa: PLR2004
        month = 1 if self._current_month.month == 12 else self._current_month.month + 1  # noqa: PLR2004
        self._current_month = date(year, month, 1)

        # Update model state
        self.beginResetModel()
        self._transactions = self._load_transactions()
        self.endResetModel()

        self.current_month_changed.emit()

    @Slot()
    def previous_month(self) -> None:
        """Move to the previous month."""
        year = self._current_month.year - (1 if self._current_month.month == 1 else 0)
        month = 12 if self._current_month.month == 1 else self._current_month.month - 1
        self._current_month = date(year, month, 1)

        # Update model state
        self.beginResetModel()
        self._transactions = self._load_transactions()
        self.endResetModel()

        self.current_month_changed.emit()

    @QEnum
    class TransactionRole(IntEnum):
        """Roles coresponding to model data."""

        IdRole = Qt.ItemDataRole.UserRole + 1
        NameRole = Qt.ItemDataRole.DisplayRole
        AmountRole = Qt.ItemDataRole.UserRole + 2
        DateRole = Qt.ItemDataRole.UserRole + 3
        CategoryRole = Qt.ItemDataRole.UserRole + 4
        TypeRole = Qt.ItemDataRole.UserRole + 5

    @dataclass
    class Transaction:
        """Data structure for individual transaction."""

        id: int
        name: str
        amount: Decimal
        date: date
        category: str
        type: TransactionType

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._current_month = datetime.datetime.now().astimezone().date()  # use local time zone
        self._transactions = self._load_transactions()

    def _load_transactions(self) -> list[Transaction]:
        """Load transactions for current month from the database."""
        start_of_month = self._current_month.replace(day=1)

        # Calculate first day of next month
        if self._current_month.month == 12:  # noqa: PLR2004
            start_of_next_month = date(self._current_month.year + 1, 1, 1)
        else:
            start_of_next_month = date(start_of_month.year, start_of_month.month + 1, 1)

        # Grab transactions based on the start/end of the month
        with db.create_session() as session:
            stmt = select(models.Transaction).where(
                models.Transaction.execution_date >= start_of_month,
                models.Transaction.execution_date < start_of_next_month,
            )

            transactions = [
                self.Transaction(
                    transaction.id,
                    transaction.name,
                    transaction.amount,
                    transaction.execution_date,
                    transaction.category,
                    transaction.transaction_type,
                )
                for transaction in session.scalars(stmt).all()
            ]

        # Return sorted transactions by day (descending)
        return sorted(transactions, key=lambda t: t.date.day, reverse=True)

    def _get_insert_index(self, transaction_date: date) -> int:
        insert_index = len(self._transactions)

        for i, transaction in enumerate(self._transactions):
            if transaction.date.day <= transaction_date.day:
                insert_index = i
                break

        return insert_index

    def rowCount(self, parent: QModelIndex = QModelIndex()) -> int:  # noqa: ARG002, B008, N802
        """Return the number of rows in the model."""
        return len(self._transactions)

    def data(self, index: QModelIndex, role: int) -> str | QDate | int | None:
        """Return the data for a given role and index in the model."""
        row = index.row()
        t_role = TransactionModel.TransactionRole  # type: ignore  # noqa: PGH003 # Pylance doesn't recognize TransactionRole

        if row < self.rowCount():
            transaction = self._transactions[row]

            data = {
                t_role.IdRole: transaction.id,
                t_role.NameRole: transaction.name,
                t_role.AmountRole: str(transaction.amount),
                t_role.DateRole: QDate(
                    transaction.date.year,
                    transaction.date.month,
                    transaction.date.day,
                ),
                t_role.CategoryRole: transaction.category,
                t_role.TypeRole: transaction.type.value,
            }

            if role in data:
                return data[role]

        return None

    def roleNames(self) -> dict[int, QByteArray]:  # noqa: N802
        """Map role enum values to QByteArray identifiers for QML property access."""
        roles = super().roleNames()
        t_role = TransactionModel.TransactionRole  # type: ignore  # noqa: PGH003 # Pylance doesn't recognize TransactionRole

        roles[t_role.IdRole] = QByteArray(b"index")  # not to be confused with qml Ids
        roles[t_role.NameRole] = QByteArray(b"name")
        roles[t_role.AmountRole] = QByteArray(b"amount")
        roles[t_role.DateRole] = QByteArray(b"date")
        roles[t_role.CategoryRole] = QByteArray(b"category")
        roles[t_role.TypeRole] = QByteArray(b"type")

        return roles

    @Slot()
    def update_model(self) -> None:
        """Update the model to reflect current transactions in the db."""
        self.beginResetModel()
        self._transactions = self._load_transactions()
        self.endResetModel()

    @Slot(str, str, QDate, str, str, result=dict)
    def append(
        self,
        name: str,
        amount: str,
        date: QDate,
        category: str,
        transaction_type: str,
    ) -> OperationResult:
        """Create a new transaction and append it to the model and database."""
        try:
            # Convert QML data to appropriate Python types
            name = strip_name(name)
            decimal_amount = Decimal(amount)
            py_date = cast("date", date.toPython())
            transaction_type_enum = TransactionType(transaction_type.lower())

            with db.create_session() as session:
                new_transaction = models.Transaction(
                    name=name,
                    amount=decimal_amount,
                    execution_date=py_date,
                    category=category,
                    transaction_type=transaction_type_enum,
                )

                session.add(new_transaction)
                session.flush()  # populate transaction id
                transaction_id = new_transaction.id  # store id for later use
                session.commit()

            # Log new transaction creation
            logger.info(
                "Created transaction: Id: %s, Name: %s, Amount: %s, Date: %s, Category: %s, "
                "Type: %s",
                transaction_id,
                name,
                decimal_amount,
                py_date,
                category,
                transaction_type_enum.value,
            )

            # Check if data model needs to be updated
            current_month = self._current_month

            if py_date.month == current_month.month and py_date.year == current_month.year:
                # Get new insertion position
                insert_index = self._get_insert_index(py_date)

                # Update data model
                self.beginInsertRows(QModelIndex(), insert_index, insert_index)
                self._transactions.insert(
                    insert_index,
                    self.Transaction(
                        id=transaction_id,
                        name=name,
                        amount=decimal_amount,
                        date=py_date,
                        category=category,
                        type=transaction_type_enum,
                    ),
                )
                self.endInsertRows()

        except EmptyStringError as e:
            logger.exception("Failed to create transaction")
            return {"success": False, "error": str(e)}
        except Exception:
            logger.exception("Failed to create transaction")
            return {"success": False, "error": "An unexpected error occurred."}
        else:
            return {"success": True}

    @Slot(int, str, str, QDate, str, str, result=dict)
    def edit(  # noqa: PLR0913
        self,
        transaction_id: int,
        name: str,
        amount: str,
        date: QDate,
        category: str,
        transaction_type: str,
    ) -> OperationResult:
        """Edit an existing transaction."""
        try:
            # Convert QML data to appropriate Python types
            name = strip_name(name)
            decimal_amount = Decimal(amount)
            py_date = cast("date", date.toPython())
            transaction_type_enum = TransactionType(transaction_type.lower())

            with db.create_session() as session:
                # Get the transaction to edit
                stmt = select(models.Transaction).where(models.Transaction.id == transaction_id)
                transaction = session.scalars(stmt).one_or_none()

                if transaction is None:
                    # Could not find transaction to edit
                    # This is likely due to an edge case where the transaction gets deleted
                    # because of a category deletion while the user is editing it:

                    # Create new transaction instead
                    logger.debug(
                        "Could not find transaction with id %s, creating a new one.",
                        transaction_id,
                    )

                    return self.append(name, amount, date, category, transaction_type)

                # Gather before data for logging
                before_data = (
                    f"Name: {transaction.name}, "
                    f"Amount: {transaction.amount}, Date: {transaction.execution_date}, "
                    f"Category: {transaction.category}, Type: {transaction.transaction_type.value}"
                )

                # Update the transaction fields
                transaction.name = name
                transaction.amount = decimal_amount
                transaction.execution_date = py_date
                transaction.category = category
                transaction.transaction_type = transaction_type_enum

                session.commit()

            # Log transaction edit
            logger.info(
                "Edited transaction with Id=%d: From: %s To: Name: %s, Amount: %s, "
                "Date: %s, Category: %s, Type: %s",
                transaction_id,
                before_data,
                name,
                decimal_amount,
                py_date.isoformat(),
                category,
                transaction_type_enum.value,
            )

            # Check if data model needs to be updated
            model_transaction = next(
                (t for t in self._transactions if t.id == transaction_id),
                None,
            )

            if model_transaction:
                # Check if repositioning is needed
                row_index = self._transactions.index(model_transaction)

                if (
                    py_date.month == self._current_month.month
                    and py_date.year == self._current_month.year
                ):
                    date_changed = model_transaction.date != py_date

                    # Update data model object
                    model_transaction.name = name
                    model_transaction.amount = decimal_amount
                    model_transaction.date = py_date
                    model_transaction.category = category
                    model_transaction.type = transaction_type_enum

                    if not date_changed:
                        # Notify QML about the changes
                        model_index = self.index(  # Qt method that returns a QModelIndex
                            row_index,
                            0,
                        )
                        self.dataChanged.emit(model_index, model_index)
                    else:
                        # Remove from current position
                        self.beginRemoveRows(QModelIndex(), row_index, row_index)
                        self._transactions.pop(row_index)
                        self.endRemoveRows()

                        # Get new insertion position

                        insert_index = self._get_insert_index(py_date)

                        # Insert at newly calculated position
                        self.beginInsertRows(QModelIndex(), insert_index, insert_index)
                        self._transactions.insert(insert_index, model_transaction)
                        self.endInsertRows()
                else:
                    # Month changed, transaction no longer on displayed month:

                    # Remove the transaction from the model
                    self.beginRemoveRows(QModelIndex(), row_index, row_index)
                    self._transactions.pop(row_index)
                    self.endRemoveRows()

        except EmptyStringError as e:
            logger.exception("Failed to edit transaction")
            return {"success": False, "error": str(e)}
        except Exception:
            logger.exception("Failed to edit transaction")
            return {"success": False, "error": "An unexpected error occurred."}
        else:
            return {"success": True}

    @Slot(int, result=dict)
    def remove(self, transaction_id: int) -> OperationResult:
        """Remove a transaction from the data model and db."""
        try:
            with db.create_session() as session:
                stmt = select(models.Transaction).where(
                    models.Transaction.id == transaction_id,
                )

                to_remove = session.scalars(stmt).one()

                # Gather data for logging
                removed_transaction_info = (
                    f"Id: {to_remove.id}, Name: {to_remove.name}, Amount: {to_remove.amount}, "
                    f"Date: {to_remove.execution_date}, Category: {to_remove.category}, "
                    f"Type: {to_remove.transaction_type.value}"
                )

                # Delete transaction
                session.delete(to_remove)
                session.commit()

            # Check if data model needs to be updated
            model_transaction = next(
                (t for t in self._transactions if t.id == transaction_id),
                None,
            )

            if model_transaction:
                index = self._transactions.index(model_transaction)

                # Remove the category from the model
                self.beginRemoveRows(QModelIndex(), index, index)
                self._transactions.pop(index)
                self.endRemoveRows()

            # Log transaction removal
            logger.info("Deleted transaction: %s", removed_transaction_info)

        except Exception:
            logger.exception("Failed to remove transaction")
            return {"success": False, "error": "An unexpected error occurred."}
        else:
            return {"success": True}
