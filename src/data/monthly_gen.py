import calendar
import datetime
import logging
from datetime import date

from sqlalchemy import select

from data import db
from data.models import MonthlyTransaction, Transaction

# create logger for module
logger = logging.getLogger(__name__)

MONTHS_IN_YEAR = 12


class GenerationError(Exception):
    def __init__(self) -> None:
        super().__init__("Failed to generate transactions for monthly transaction.")


def gen_transactions(monthly_transaction_id: int) -> None:
    """Generate transactions for a given monthly transaction by ID.

    Will generate transactions up until current date.
    Transactions previously generated will not be generated again.
    """
    try:
        with db.create_session() as session:
            # Fetch monthly transaction
            stmt = select(MonthlyTransaction).where(MonthlyTransaction.id == monthly_transaction_id)
            monthly_transaction = session.scalars(stmt).one()

            # Check if the monthly transaction is already fully generated (based on current date)

            current_date = datetime.datetime.now().astimezone().date()

            generated_until = monthly_transaction.generated_until or monthly_transaction.start_date
            end_date = monthly_transaction.end_date or current_date

            if generated_until in (current_date, end_date) and monthly_transaction.generated_until:
                # No new transactions to generate:
                return

            # Generate transactions

            loop_conclusion = min(current_date, end_date)
            loop_log = []

            while generated_until <= loop_conclusion:
                # Get day of month while accounting for month length
                # Month has 30 days but day of month is 31, adjust to last day of month
                day_of_month = min(
                    monthly_transaction.day_of_month,
                    calendar.monthrange(generated_until.year, generated_until.month)[1],
                )

                month_gen_date = date(generated_until.year, generated_until.month, day_of_month)

                if month_gen_date <= loop_conclusion and month_gen_date >= generated_until:
                    # Create transaction for this month
                    transaction = Transaction(
                        name=monthly_transaction.name,
                        amount=monthly_transaction.amount,
                        transaction_type=monthly_transaction.transaction_type,
                        execution_date=month_gen_date,
                        category=monthly_transaction.category,
                        monthly_transaction_id=monthly_transaction.id,
                    )
                    session.add(transaction)

                    # Populate id, format log string and append it to loop_log

                    session.flush()  # Slows things down but I would not consider this "hot" code

                    loop_log.append(
                        f"Created transaction: "
                        f"Name: {transaction.name}, amount {transaction.amount}, "
                        f"transaction_type: {transaction.transaction_type.value}, "
                        f"execution_date: {transaction.execution_date}, "
                        f"category: {transaction.category}, "
                        f"monthly_transaction_id: {transaction.monthly_transaction_id}, ",
                    )

                # Set generated_until to next month

                next_month = (
                    generated_until.month + 1 if generated_until.month < MONTHS_IN_YEAR else 1
                )
                next_year = (
                    generated_until.year
                    if generated_until.month < MONTHS_IN_YEAR
                    else generated_until.year + 1
                )

                generated_until = date(next_year, next_month, 1)

            # Update generated_until in monthly transaction
            monthly_transaction.generated_until = loop_conclusion

            # Commit the session
            session.commit()

            # Log the transactions created
            if len(loop_log) > 0:
                for transaction_creation in loop_log:
                    logger.info(transaction_creation)

    except Exception as err:
        logger.exception(
            "Failed to generate transactions for monthly transaction with Id: %d",
            monthly_transaction_id,
        )
        raise GenerationError from err


def gen_transactions_for_all() -> None:
    """Generate missing transactions for all monthly transactions in the DB.

    Will generate missing transactions up until current date.
    Transactions previously generated will not be generated again.
    """
    try:
        with db.create_session() as session:
            stmt = select(MonthlyTransaction)

            monthly_transactions = session.scalars(stmt).all()

            for monthly_transaction in monthly_transactions:
                gen_transactions(monthly_transaction.id)
    except Exception:
        logger.exception("Failed to generate transactions for monthly transactions.")
