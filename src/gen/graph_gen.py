import contextlib
import logging

import matplotlib as mpl
import matplotlib.pyplot as plt
import pandas as pd

from data import db
from data.models import Transaction, TransactionType
from utility.save import data_folder_path

logging.getLogger("matplotlib.font_manager").setLevel(logging.ERROR)


def load_transactions_as_dataframe() -> pd.DataFrame:
    """Load all transactions from the database and return them as a pandas DataFrame."""
    session = db.create_session()

    try:
        transactions = session.query(Transaction).all()

        data = [
            {
                "Name": t.name,
                "Amount": float(t.amount),
                "OfType": "Income" if t.transaction_type == TransactionType.INCOME else "Expense",
                "DateOf": t.execution_date,
                "Category": t.category,
            }
            for t in transactions
        ]

        if not data:
            return pd.DataFrame(columns=["Name", "Amount", "OfType", "DateOf", "Category"])

        dataframe = pd.DataFrame(data)
        dataframe["DateOf"] = pd.to_datetime(dataframe["DateOf"])  # Ensure datetime format
        return dataframe

    finally:
        session.close()


def plot_daily_transactions(year: int, month: int) -> None:
    """Use load_transactions_as_dataframe generate a daily transaction graph and save it."""
    dataframe = load_transactions_as_dataframe()
    if dataframe.empty:
        plt.figure(figsize=(6, 4))
        plt.title(f"No Transactions for {year}-{month:02d}", fontsize=12)
        plt.text(
            0.5,
            0.5,
            "Database empty. Please add data first.",
            ha="center",
            va="center",
            fontsize=10,
        )
        plt.axis("off")
        output_dir = data_folder_path() / "graphs"
        output_dir.mkdir(exist_ok=True)
        output_path = output_dir / "dailychart.png"
        plt.savefig(output_path)
        plt.close()
        return
    # Filter data for the given year & month
    filtered_df = dataframe[
        (dataframe["DateOf"].dt.year == year) & (dataframe["DateOf"].dt.month == month)
    ].copy()

    if filtered_df.empty:
        plt.figure(figsize=(6, 4))
        plt.title(f"No Transactions for {year}-{month:02d}", fontsize=12)
        plt.text(0.5, 0.5, "No data available", ha="center", va="center", fontsize=10)
        plt.axis("off")
        output_dir = data_folder_path() / "graphs"
        output_dir.mkdir(exist_ok=True)
        output_path = output_dir / "dailychart.png"
        plt.savefig(output_path)
        plt.close()
        return

    # Group by day and calculate income and expense
    income_df = (
        filtered_df[filtered_df["OfType"] == "Income"]
        .groupby(filtered_df["DateOf"].dt.day)["Amount"]
        .sum()
    )
    expense_df = (
        filtered_df[filtered_df["OfType"] == "Expense"]
        .groupby(filtered_df["DateOf"].dt.day)["Amount"]
        .sum()
    )

    valid_days = range(1, (filtered_df["DateOf"].dt.days_in_month.max() + 1))
    income_df = income_df.reindex(valid_days, fill_value=0)
    expense_df = expense_df.reindex(valid_days, fill_value=0)

    plt.figure(figsize=(6, 4))

    bar_width = 0.35  # Narrower bars to reduce clutter
    index = valid_days

    # Plot bars
    plt.bar(index, income_df, bar_width, label="Income", color="green")
    plt.bar([i + bar_width for i in index], expense_df, bar_width, label="Expense", color="red")

    # Plot settings
    plt.xlabel("Day", fontsize=10)
    plt.ylabel("Amount (€)", fontsize=10)
    plt.title(f"Daily Income & Expenses for {year}-{month:02d}", fontsize=12)
    plt.xticks(fontsize=8, rotation=45)
    plt.yticks(fontsize=8)

    plt.grid(visible=True, axis="y", linestyle="--", alpha=0.7)

    plt.legend(
        fontsize=8,
        loc="upper left",
        bbox_to_anchor=(1, 1),
    )

    plt.tight_layout()

    # Save plot
    output_dir = data_folder_path() / "graphs"
    output_dir.mkdir(exist_ok=True)
    output_path = output_dir / "dailychart.png"
    plt.savefig(output_path)
    plt.close()


def plot_monthly_trend(year: int) -> None:
    """Use load_transactions_as_dataframe generate a monthly trend graph and save it."""
    dataframe = load_transactions_as_dataframe()

    if dataframe.empty:
        plt.figure(figsize=(6, 4))
        plt.title(f"No Transactions for {year}", fontsize=12)
        plt.text(
            0.5,
            0.5,
            "Database empty. Please add data first.",
            ha="center",
            va="center",
            fontsize=10,
        )
        plt.axis("off")
        output_dir = data_folder_path() / "graphs"
        output_dir.mkdir(exist_ok=True)
        output_path = output_dir / "monthlychart.png"
        plt.savefig(output_path)
        plt.close()
        return
    # Filter for the given year
    filtered_df = dataframe[dataframe["DateOf"].dt.year == year].copy()
    if filtered_df.empty:
        plt.figure(figsize=(6, 4))
        plt.title(f"No Transactions for {year}", fontsize=12)
        plt.text(0.5, 0.5, "No data available", ha="center", va="center", fontsize=10)
        plt.axis("off")
        output_dir = data_folder_path() / "graphs"
        output_dir.mkdir(exist_ok=True)
        output_path = output_dir / "monthlychart.png"
        plt.savefig(output_path)
        plt.close()
        return

    # Group by month and calculate income and expense
    income_df = (
        filtered_df[filtered_df["OfType"] == "Income"]
        .groupby(filtered_df["DateOf"].dt.month)["Amount"]
        .sum()
        .reset_index()
    )
    expense_df = (
        filtered_df[filtered_df["OfType"] == "Expense"]
        .groupby(filtered_df["DateOf"].dt.month)["Amount"]
        .sum()
        .reset_index()
    )

    # Fill missing months with 0
    income_df = income_df.set_index("DateOf").reindex(range(1, 13), fill_value=0).reset_index()
    expense_df = expense_df.set_index("DateOf").reindex(range(1, 13), fill_value=0).reset_index()

    income_df.columns = ["Month", "Income"]
    expense_df.columns = ["Month", "Expense"]

    plt.figure(figsize=(6, 4))
    bar_width = 0.35
    index = range(1, 13)

    plt.bar(index, income_df["Income"], bar_width, label="Income", color="green")
    plt.bar(
        [i + bar_width for i in index],
        expense_df["Expense"],
        bar_width,
        label="Expense",
        color="red",
    )

    # Plot settings
    plt.xlabel("Month")
    plt.ylabel("Amount (€)")
    plt.title(f"Income & Expenses Trend for {year}")
    plt.xticks([i + bar_width / 2 for i in index], income_df["Month"].astype(str).tolist())
    plt.grid(visible=True, axis="y", linestyle="--", alpha=0.7)
    plt.legend()
    plt.tight_layout()

    # Save plot
    output_dir = data_folder_path() / "graphs"
    output_dir.mkdir(exist_ok=True)
    output_path = output_dir / "monthlychart.png"
    plt.savefig(output_path)
    plt.close()


def plot_income_vs_expense(year: int) -> None:
    """Use load_transactions_as_dataframe generate a income vs expenses graph and save it."""
    dataframe = load_transactions_as_dataframe()

    if dataframe.empty:
        plt.figure(figsize=(6, 4))
        plt.title(f"No Transactions for {year}", fontsize=12)
        plt.text(
            0.5,
            0.5,
            "Database empty. Please add data first.",
            ha="center",
            va="center",
            fontsize=10,
        )
        plt.axis("off")
        output_dir = data_folder_path() / "graphs"
        output_dir.mkdir(exist_ok=True)
        output_path = output_dir / "income_vs_expense.png"
        plt.savefig(output_path)
        plt.close()
        return
    # Filter data for the given year
    filtered_df = dataframe[dataframe["DateOf"].dt.year == year]

    if filtered_df.empty:
        plt.figure(figsize=(6, 4))
        plt.title(f"No Income or Expenses for {year}", fontsize=12)
        plt.text(0.5, 0.5, "No data available", ha="center", va="center", fontsize=10)
        plt.axis("off")
        output_dir = data_folder_path() / "graphs"
        output_dir.mkdir(exist_ok=True)
        output_path = output_dir / "income_vs_expense.png"
        plt.savefig(output_path)
        plt.close()
        return

    total_income = filtered_df[filtered_df["OfType"] == "Income"]["Amount"].sum()
    total_expense = filtered_df[filtered_df["OfType"] == "Expense"]["Amount"].sum()

    plt.figure(figsize=(6, 4))
    plt.bar(["Income", "Expenses"], [total_income, total_expense], color=["green", "red"])

    # Plot settings
    plt.ylabel("Amount (€)")
    plt.title(f"Total Income vs. Expenses for {year}")
    plt.grid(axis="y", linestyle="--", alpha=0.7)
    plt.tight_layout()

    # Save plot
    output_dir = data_folder_path() / "graphs"
    output_dir.mkdir(exist_ok=True)
    output_path = output_dir / "income_vs_expense.png"
    plt.savefig(output_path)
    plt.close()


def plot_expense_distribution(year: int) -> None:
    """Use load_transactions_as_dataframe generate an expense distribution graph and save it."""
    dataframe = load_transactions_as_dataframe()

    if dataframe.empty:
        plt.figure(figsize=(6, 4))
        plt.title(f"No Transactions for {year}", fontsize=12)
        plt.text(
            0.5,
            0.5,
            "Database empty. Please add data first.",
            ha="center",
            va="center",
            fontsize=10,
        )
        plt.axis("off")
        output_dir = data_folder_path() / "graphs"
        output_dir.mkdir(exist_ok=True)
        output_path = output_dir / "expense_distribution.png"
        plt.savefig(output_path)
        plt.close()
        return
    # Filter for the given year and only include expenses
    expense_df = dataframe[
        (dataframe["DateOf"].dt.year == year) & (dataframe["OfType"] == "Expense")
    ]

    if expense_df.empty:
        plt.figure(figsize=(6, 4))
        plt.title(f"No Expenses for {year}", fontsize=12)
        plt.text(0.5, 0.5, "No data available", ha="center", va="center", fontsize=10)
        plt.axis("off")
        output_dir = data_folder_path() / "graphs"
        output_dir.mkdir(exist_ok=True)
        output_path = output_dir / "expense_distribution.png"
        plt.savefig(output_path)
        plt.close()
        return

    # Group expenses by category
    category_totals = expense_df.groupby("Category")["Amount"].sum()

    category_labels = category_totals.index.astype(str).tolist()

    # Generate colors
    num_categories = len(category_totals)
    colormap = mpl.colormaps["Set3"]
    colors = [colormap(i / num_categories) for i in range(num_categories)]

    # Plot settings
    fig, ax = plt.subplots(figsize=(6, 4))
    ax.pie(
        category_totals,
        labels=category_labels,
        autopct="%1.1f%%",
        colors=colors,
        startangle=140,
        pctdistance=0.8,
        labeldistance=1.1,
    )
    ax.set_title(f"Expense Distribution by Category ({year})")
    ax.set_aspect("equal")  # Ensure pie is a circle

    # Save plot
    output_dir = data_folder_path() / "graphs"
    output_dir.mkdir(exist_ok=True)
    output_path = output_dir / "expense_distribution.png"
    plt.savefig(output_path)
    plt.close()


def close_graphs() -> None:
    """Delete generated graphs before quitting."""
    dry_run = False
    folder = data_folder_path() / "graphs"  # delete pngs before quitting
    if not folder.exists() or not folder.is_dir():
        return
    files = list(folder.glob("*.png"))  # list so glob runs once

    for file_path in files:
        if file_path.exists() and not dry_run:
            with contextlib.suppress(FileNotFoundError, PermissionError):
                file_path.unlink()
