import enum

import xlsxwriter
from PySide6.QtWidgets import QFileDialog
from sqlalchemy import extract, inspect

from data import db
from data.models import MonthlyTransaction, Transaction, TransactionCategory


def export_database() -> None:
    """Export entire database into excel."""
    excel_path, _ = QFileDialog.getSaveFileName(
        None,
        "Save Excel File As",
        "database_export.xlsx",
        "Excel Files (*.xlsx)",
    )

    if not excel_path:
        return

    workbook = xlsxwriter.Workbook(str(excel_path))

    models = [Transaction, TransactionCategory, MonthlyTransaction]
    db.initialize()

    with db.create_session() as session:
        for model in models:
            table_name = model.__tablename__
            worksheet = workbook.add_worksheet(name=table_name[:31])

            # inspect columns
            mapper = inspect(model)
            columns = [col.key for col in mapper.columns]

            # write headers
            for col_idx, col_name in enumerate(columns):
                worksheet.write(0, col_idx, col_name)

            # query all data
            rows = session.query(model).all()

            # write rows
            for row_idx, row in enumerate(rows, start=1):
                for col_idx, col_name in enumerate(columns):
                    value = getattr(row, col_name)

                    if isinstance(value, enum.Enum):
                        value = value.value
                    elif hasattr(value, "isoformat"):
                        value = value.isoformat()

                    worksheet.write(row_idx, col_idx, value)

    workbook.close()


def export_transactions_by_month(month: int, year: int) -> None:
    """Export transactions for given month and year into excel."""
    excel_path, _ = QFileDialog.getSaveFileName(
        None,
        "Save Excel File As",
        f"transactions_{year}_{month:02}.xlsx",
        "Excel Files (*.xlsx)",
    )

    if not excel_path:
        return

    workbook = xlsxwriter.Workbook(str(excel_path))
    worksheet = workbook.add_worksheet(name="Transactions")

    db.initialize()

    with db.create_session() as session:
        # inspect columns dynamically
        mapper = inspect(Transaction)
        columns = [col.key for col in mapper.columns]

        # write headers
        for col_idx, col_name in enumerate(columns):
            worksheet.write(0, col_idx, col_name)

        # filter transactions by given month and year
        rows = (
            session.query(Transaction)
            .filter(
                extract("month", Transaction.execution_date) == month,
                extract("year", Transaction.execution_date) == year,
            )
            .all()
        )

        # write rows
        for row_idx, row in enumerate(rows, start=1):
            for col_idx, col_name in enumerate(columns):
                value = getattr(row, col_name)

                if isinstance(value, enum.Enum):
                    value = value.value
                elif hasattr(value, "isoformat"):
                    value = value.isoformat()

                worksheet.write(row_idx, col_idx, value)

    workbook.close()
