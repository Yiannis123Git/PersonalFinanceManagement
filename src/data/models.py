import enum
from datetime import date
from decimal import Decimal

from sqlalchemy import (
    Date,
    Enum,
    ForeignKey,
    Integer,
    Numeric,
    String,
)
from sqlalchemy.orm import Mapped, declarative_base, mapped_column

Base = declarative_base()


class TransactionType(enum.Enum):
    INCOME = "income"
    EXPENSE = "expense"


class Transaction(Base):
    __tablename__ = "transactions"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String())
    amount: Mapped[Decimal] = mapped_column(Numeric(precision=10, scale=2))
    transaction_type: Mapped[TransactionType] = mapped_column(Enum(TransactionType))
    execution_date: Mapped[date] = mapped_column(Date())
    category: Mapped[str] = mapped_column(
        String(),
        ForeignKey("transaction_categories.name"),
    )


class TransactionCategory(Base):
    __tablename__ = "transaction_categories"

    name: Mapped[str] = mapped_column(String(), primary_key=True)
    transaction_type: Mapped[TransactionType] = mapped_column(Enum(TransactionType))


class MonthlyTransaction(Base):
    __tablename__ = "monthly_transactions"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String())
    amount: Mapped[Decimal] = mapped_column(Numeric(precision=10, scale=2))
    transaction_type: Mapped[TransactionType] = mapped_column(Enum(TransactionType))
    day_of_month: Mapped[int] = mapped_column(Integer())
    start_date: Mapped[date] = mapped_column(Date())
    end_date: Mapped[date] = mapped_column(Date(), nullable=True)
    category: Mapped[str] = mapped_column(
        String(),
        ForeignKey("transaction_categories.name"),
    )
