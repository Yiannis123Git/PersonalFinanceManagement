from collections.abc import Callable

from PySide6.QtCore import Property, QObject, Signal


def qt_property[T](
    property_type: type[T],
    property_name: str,
    signal_attr_name: str,
) -> tuple[Property, Callable[[QObject], T], Callable[[QObject, T], None], Signal]:
    """Create a Qt property.

    Args:
        property_type (type): The type of the property.
        property_name (str): Property name. A private attribute with _{property_name} must exist.
        signal_attr_name (str): The name of the signal to emit when the property changes.

    Returns:
        tuple: A tuple containing getter, setter, and the qt property object.
            - Property: The Qt Property object
            - Callable[[QObject], property_type]: Getter to retrieve the property value
            - Callable[[QObject], property_type], None]: Setter to modify the property value
            - Signal: The signal tied to the property

    """
    private_attribute = f"_{property_name}"
    signal = Signal(property_type)

    def getter(self: QObject) -> T:
        """Qt property getter."""
        return getattr(self, private_attribute)

    def setter(self: QObject, value: T) -> None:
        """Qt property setter."""
        if getattr(self, private_attribute) != value:
            setattr(self, private_attribute, value)
            getattr(self, signal_attr_name).emit(value)

    return Property(property_type, getter, setter, notify=signal), getter, setter, signal  # type: ignore  # noqa: PGH003
