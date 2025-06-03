import logging
from dataclasses import dataclass
from datetime import date
from decimal import Decimal
from enum import IntEnum
from typing import NotRequired, TypedDict, cast

from PySide6.QtCore import (
    QAbstractListModel,
    QByteArray,
    QDate,
    QEnum,
    QModelIndex,
    QObject,
    Qt,
    Slot,
)
from PySide6.QtQml import QmlElement
from sqlalchemy import delete, select

from data import db, models, monthly_gen
from data.models import Transaction, TransactionType
from data.monthly_gen import GenerationError
from py_qml.common import EmptyStringError, OperationResult, strip_name

QML_IMPORT_NAME = "PFM.Models"
QML_IMPORT_MAJOR_VERSION = 1

# Create logger for context
logger = logging.getLogger(__name__)


@QmlElement
class MonthlyTransactionModel(QAbstractListModel):
    @QEnum
    class MonthlyTransactionRole(IntEnum):
        """Roles coresponding to model data."""

        IdRole = Qt.ItemDataRole.UserRole + 1
        NameRole = Qt.ItemDataRole.DisplayRole
        AmountRole = Qt.ItemDataRole.UserRole + 2
        CategoryRole = Qt.ItemDataRole.UserRole + 3
        TypeRole = Qt.ItemDataRole.UserRole + 4
        StartDateRole = Qt.ItemDataRole.UserRole + 5
        EndDateRole = Qt.ItemDataRole.UserRole + 6
        DayOfMonthRole = Qt.ItemDataRole.UserRole + 7

    @dataclass
    class MonthlyTransaction:
        """Data structure for recurring transactions."""

        id: int
        name: str
        amount: Decimal
        category: str
        type: TransactionType
        start_date: date
        end_date: date | None
        day_of_month: int

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._monthly_transactions = self._load_monthly_transactions()

    def _load_monthly_transactions(self) -> list[MonthlyTransaction]:
        with db.create_session() as session:
            stmt = select(models.MonthlyTransaction)

            monthly_transactions = [
                self.MonthlyTransaction(
                    monthly_transaction.id,
                    monthly_transaction.name,
                    monthly_transaction.amount,
                    monthly_transaction.category,
                    monthly_transaction.transaction_type,
                    monthly_transaction.start_date,
                    monthly_transaction.end_date,
                    monthly_transaction.day_of_month,
                )
                for monthly_transaction in session.scalars(stmt).all()
            ]

        # return sorted monthly transactions by name
        return sorted(monthly_transactions, key=lambda x: x.name)

    def _get_insert_index(self, name: str) -> int:
        insert_index = len(self._monthly_transactions)

        for i, transaction in enumerate(self._monthly_transactions):
            if transaction.name > name:
                insert_index = i
                break

        return insert_index

    def rowCount(self, parent: QModelIndex = QModelIndex()) -> int:  # noqa: ARG002, B008, N802
        """Return the number of rows in the model."""
        return len(self._monthly_transactions)

    def data(self, index: QModelIndex, role: int) -> str | QDate | int | None:
        """Return the data for a given role and index in the model."""
        row = index.row()
        mt_role = MonthlyTransactionModel.MonthlyTransactionRole  # type: ignore  # noqa: PGH003 # Pylance doesn't recognize TransactionRole

        if row < self.rowCount():
            monthly_transaction = self._monthly_transactions[row]

            data = {
                mt_role.IdRole: monthly_transaction.id,
                mt_role.NameRole: monthly_transaction.name,
                mt_role.AmountRole: str(monthly_transaction.amount),
                mt_role.CategoryRole: monthly_transaction.category,
                mt_role.TypeRole: monthly_transaction.type.value,
                mt_role.StartDateRole: QDate(
                    monthly_transaction.start_date.year,
                    monthly_transaction.start_date.month,
                    monthly_transaction.start_date.day,
                ),
                mt_role.EndDateRole: (
                    QDate(
                        monthly_transaction.end_date.year,
                        monthly_transaction.end_date.month,
                        monthly_transaction.end_date.day,
                    )
                    if monthly_transaction.end_date
                    else None
                ),
                mt_role.DayOfMonthRole: monthly_transaction.day_of_month,
            }

            if role in data:
                return data[role]

        return None

    def roleNames(self) -> dict[int, QByteArray]:  # noqa: N802
        """Map role enum values to QByteArray identifiers for QML property access."""
        roles = super().roleNames()
        t_role = MonthlyTransactionModel.MonthlyTransactionRole  # type: ignore  # noqa: PGH003 # Pylance doesn't recognize TransactionRole

        roles[t_role.IdRole] = QByteArray(b"index")  # not to be confused with qml Ids
        roles[t_role.NameRole] = QByteArray(b"name")
        roles[t_role.AmountRole] = QByteArray(b"amount")
        roles[t_role.CategoryRole] = QByteArray(b"category")
        roles[t_role.TypeRole] = QByteArray(b"type")
        roles[t_role.StartDateRole] = QByteArray(b"startDate")
        roles[t_role.EndDateRole] = QByteArray(b"endDate")
        roles[t_role.DayOfMonthRole] = QByteArray(b"dayOfMonth")

        return roles

    @Slot()
    def update_model(self) -> None:
        """Update the model to reflect current monthly transactions in the db."""
        self.beginResetModel()
        self._monthly_transactions = self._load_monthly_transactions()
        self.endResetModel()

    class OptionalEndDate(TypedDict):
        """Optional end date type for monthly transactions."""

        endDate: NotRequired[QDate]

    @Slot(str, str, str, str, QDate, dict, int, result=dict)
    def append(  # noqa: PLR0913
        self,
        name: str,
        amount: str,
        category: str,
        transaction_type: str,
        start_date: QDate,
        end_date: OptionalEndDate,
        day_of_month: int,
    ) -> OperationResult:
        """Create a new transaction and append it to the model and database."""
        try:
            # Convert QML data to appropriate Python types
            name = strip_name(name)
            decimal_amount = Decimal(amount)
            transaction_type_enum = TransactionType(transaction_type.lower())
            py_start_date = cast("date", start_date.toPython())
            qml_end_date = end_date.get("endDate", None)
            py_end_date = cast("date", qml_end_date.toPython()) if qml_end_date else None
            py_end_date = (
                date(py_end_date.year, py_end_date.month, py_end_date.day) if py_end_date else None
            )  # Remove QML inherited time stamp (this is likely due to dict use in QML)

            # Create new monthly transaction
            with db.create_session() as session:
                new_monthly_transaction = models.MonthlyTransaction(
                    name=name,
                    amount=decimal_amount,
                    transaction_type=transaction_type_enum,
                    start_date=py_start_date,
                    end_date=py_end_date if py_end_date else None,
                    day_of_month=day_of_month,
                    category=category,
                )

                session.add(new_monthly_transaction)

                session.flush()  # populate monthly transaction id
                monthly_transaction_id = new_monthly_transaction.id  # Store id
                session.commit()

            # Log monthly transaction creation
            logger.info(
                "Monthly transaction created: Name: %s, Amount: %s, Category: %s, "
                "Type: %s, Start Date: %s, End Date: %s, Day of Month: %d",
                name,
                decimal_amount,
                category,
                transaction_type_enum.value,
                py_start_date,
                py_end_date if py_end_date else "None",
                day_of_month,
            )

            # Update data model

            insert_index = self._get_insert_index(name)

            self.beginInsertRows(QModelIndex(), insert_index, insert_index)
            self._monthly_transactions.insert(
                insert_index,
                self.MonthlyTransaction(
                    monthly_transaction_id,
                    name,
                    decimal_amount,
                    category,
                    transaction_type_enum,
                    py_start_date,
                    py_end_date if py_end_date else None,
                    day_of_month,
                ),
            )
            self.endInsertRows()

            # Attempt to generate transactions for the new monthly transaction
            monthly_gen.gen_transactions(monthly_transaction_id)

        except EmptyStringError as e:
            logger.exception("Failed to create monthly transaction:")
            return {"success": False, "error": str(e)}
        except GenerationError:
            logger.exception(
                "Monthly transaction was created, but failed to generate transactions.",
            )
            return {"success": False, "error": "An unexpected error occurred."}
        except Exception:
            logger.exception("Failed to monthly create transaction")
            return {"success": False, "error": "An unexpected error occurred."}
        else:
            return {"success": True}

    @Slot(int, str, str, str, str, QDate, dict, int, result=dict)
    def edit(  # noqa: PLR0913, PLR0915
        self,
        monthly_transaction_id: int,
        name: str,
        amount: str,
        category: str,
        transaction_type: str,
        start_date: QDate,
        end_date: OptionalEndDate,
        day_of_month: int,
    ) -> OperationResult:
        """Edit an existing monthly transaction.

        Changing the start/end of a monthly transaction will cause new months to be filled.

        Ex: Start date is changed from x to y and y < x, monthly transactions will be generated
        for the new (old) past months. Same with expanding the end date.

        Date changes will not affect already generated transactions.
        """
        try:
            # Convert QML data to appropriate Python types
            name = strip_name(name)
            decimal_amount = Decimal(amount)
            transaction_type_enum = TransactionType(transaction_type.lower())
            py_start_date = cast("date", start_date.toPython())
            qml_end_date = end_date.get("endDate", None)
            py_end_date = cast("date", qml_end_date.toPython()) if qml_end_date else None
            py_end_date = (
                date(py_end_date.year, py_end_date.month, py_end_date.day) if py_end_date else None
            )  # Remove QML inherited time stamp (this is likely due to dict use in QML)

            with db.create_session() as session:
                stmt = select(models.MonthlyTransaction).where(
                    models.MonthlyTransaction.id == monthly_transaction_id,
                )

                monthly_transaction = session.scalars(stmt).one_or_none()

                if monthly_transaction is None:
                    # Could not find  monthly transaction to edit
                    # This is likely due to an edge case where the monthly transaction gets deleted
                    # because of a category deletion while the user is editing it:

                    # Create new monthly transaction instead
                    logger.debug(
                        "Could not find monthly transaction with id %s, creating a new one.",
                        monthly_transaction_id,
                    )

                    return self.append(
                        name,
                        amount,
                        category,
                        transaction_type,
                        start_date,
                        end_date,
                        day_of_month,
                    )

                # Gather data before it is changed for logging

                before_data = (
                    f"Name: {monthly_transaction.name}, "
                    f"Amount: {monthly_transaction.amount}, "
                    f"Category: {monthly_transaction.category}, "
                    f"Type: {monthly_transaction.transaction_type.value}, "
                    f"Start Date: {monthly_transaction.start_date}, "
                    f"End Date: {monthly_transaction.end_date}, "
                    f"Day of Month: {monthly_transaction.day_of_month}"
                )

                # Update monthly transaction
                monthly_transaction.name = name
                monthly_transaction.amount = decimal_amount
                monthly_transaction.category = category
                monthly_transaction.transaction_type = transaction_type_enum
                monthly_transaction.start_date = py_start_date
                monthly_transaction.end_date = py_end_date  # type: ignore  # noqa: PGH003
                monthly_transaction.day_of_month = day_of_month

                # Update associated transactions

                stmt = select(Transaction).where(
                    Transaction.monthly_transaction_id == monthly_transaction_id,
                )

                transactions = session.scalars(stmt).all()

                modified_transactions_info = []

                for transaction in transactions:
                    t_modification_info = {}

                    t_modification_info["id"] = transaction.id
                    t_modification_info["before"] = (
                        f"Name: {transaction.name}, "
                        f"Amount: {transaction.amount}, Category: {transaction.category}, "
                        f"Type: {transaction.transaction_type.value}, "
                        f"Date: {transaction.execution_date}"
                    )

                    transaction.name = name
                    transaction.amount = decimal_amount
                    transaction.category = category
                    transaction.transaction_type = transaction_type_enum

                    t_modification_info["after"] = (
                        f"Name: {transaction.name}, "
                        f"Amount: {transaction.amount}, Category: {transaction.category}, "
                        f"Type: {transaction.transaction_type.value}, "
                        f"Date: {transaction.execution_date}"
                    )

                    modified_transactions_info.append(t_modification_info)

                session.commit()

                # Log monthly transaction edit
                logger.info(
                    "Edited monthly transaction with id %d: From: %s "
                    "To: Name: %s, Amount: %s, Category: %s, Type: %s, "
                    "Start Date: %s, End Date: %s, Day of Month: %d",
                    monthly_transaction_id,
                    before_data,
                    name,
                    decimal_amount,
                    category,
                    transaction_type_enum.value,
                    py_start_date,
                    py_end_date if py_end_date else "None",
                    day_of_month,
                )

                for t_modification in modified_transactions_info:
                    logger.info(
                        "Modified transaction with id %d: From: %s To: %s",
                        t_modification["id"],
                        t_modification["before"],
                        t_modification["after"],
                    )

                # Update data model object

                model_monthly_transaction = next(
                    (m_t for m_t in self._monthly_transactions if m_t.id == monthly_transaction_id),
                )

                model_monthly_transaction.name = name
                model_monthly_transaction.amount = decimal_amount
                model_monthly_transaction.category = category
                model_monthly_transaction.type = transaction_type_enum
                model_monthly_transaction.start_date = py_start_date
                model_monthly_transaction.end_date = py_end_date
                model_monthly_transaction.day_of_month = day_of_month

                # Remove from current position
                row_index = self._monthly_transactions.index(model_monthly_transaction)
                self.beginRemoveRows(QModelIndex(), row_index, row_index)
                self._monthly_transactions.pop(row_index)
                self.endRemoveRows()

                # Calculate new position in list

                insert_index = self._get_insert_index(name)

                # Insert at new position
                self.beginInsertRows(QModelIndex(), insert_index, insert_index)
                self._monthly_transactions.insert(insert_index, model_monthly_transaction)
                self.endInsertRows()

        except EmptyStringError as e:
            logger.exception("Failed to edit monthly transaction")
            return {"success": False, "error": str(e)}
        except Exception:
            logger.exception("Failed to edit monthly transaction")
            return {"success": False, "error": "An unexpected error occurred."}
        else:
            return {"success": True}

    @Slot(int, bool, result=dict)
    def remove(
        self,
        monthly_transaction_id: int,
        delete_associated_transactions: bool,  # noqa: FBT001
    ) -> OperationResult:
        """Remove a monthly transaction from the data model and db."""
        try:
            with db.create_session() as session:
                stmt = select(models.MonthlyTransaction).where(
                    models.MonthlyTransaction.id == monthly_transaction_id,
                )

                monthly_transaction = session.scalars(stmt).one()

                removed_monthly_transaction_info = (
                    f"Id: {monthly_transaction.id}, Name: {monthly_transaction.name}, "
                    f"Amount: {monthly_transaction.amount}, "
                    f"Category: {monthly_transaction.category}, "
                    f"Type: {monthly_transaction.transaction_type.value}, "
                    f"Start Date: {monthly_transaction.start_date}, "
                    f"End Date: {monthly_transaction.end_date}, "
                    f"Day of Month: {monthly_transaction.day_of_month}"
                )

                if delete_associated_transactions:
                    stmt = select(Transaction).where(
                        Transaction.monthly_transaction_id == monthly_transaction_id,
                    )

                    transactions_deleted_info = [
                        f"Id {transaction.id}, "
                        f"Name: {transaction.name}, Amount: {transaction.amount}, "
                        f"Type: {transaction.transaction_type.value}, "
                        f"Date: {transaction.execution_date}, Category: {transaction.category}"
                        for transaction in session.scalars(stmt).all()
                    ]

                    stmt = delete(Transaction).where(
                        Transaction.monthly_transaction_id == monthly_transaction_id,
                    )

                    session.execute(stmt)

                session.delete(monthly_transaction)

                session.commit()

                # Log removal

                logger.info(
                    "Monthly transaction removed: %s",
                    removed_monthly_transaction_info,
                )

                if delete_associated_transactions:
                    for transaction_info in transactions_deleted_info:
                        logger.info("Associated transaction removed: %s", transaction_info)

                # Update data model

                index = next(
                    (
                        i
                        for i, mt in enumerate(self._monthly_transactions)
                        if mt.id == monthly_transaction_id
                    ),
                )

                self.beginRemoveRows(QModelIndex(), index, index)
                self._monthly_transactions.pop(index)
                self.endRemoveRows()

        except Exception:
            logger.exception("Failed to remove monthly transaction")
            return {"success": False, "error": "An unexpected error occurred."}
        else:
            return {"success": True}
