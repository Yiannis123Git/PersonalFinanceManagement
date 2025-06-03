from typing import NotRequired, TypedDict


class EmptyStringError(ValueError):
    def __init__(self, message: str) -> None:
        super().__init__(message)


class OperationResult(TypedDict):
    """Result of data model slot operation."""

    success: bool
    error: NotRequired[str]


def strip_name(name: str, fallback_msg: str = "Name cannot be empty.") -> str:
    """Strip leading and trailing whitespace from a name. Raise an error if the name is empty."""
    name = name.strip()
    if not name:
        raise EmptyStringError(fallback_msg)

    return name
