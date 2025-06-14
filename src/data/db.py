from __future__ import annotations

import logging
from sqlite3 import Connection as SQLite3Connection
from typing import cast

from sqlalchemy import create_engine, event
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

from utility import save

from .models import Base

# create logger for module
logger = logging.getLogger(__name__)


# Enable foreign key constraints
@event.listens_for(Engine, "connect")
def _set_sqlite_pragma(dbapi_connection: object, connection_record) -> None:  # noqa: ANN001, ARG001
    if isinstance(dbapi_connection, SQLite3Connection):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON;")
        cursor.close()


class State:
    def __init__(self) -> None:
        self._DB_NAME = "pfm"
        self._UNINITIALIZED_MSG = "Database not initialized. Call initialize_db() first."
        self._engine: Engine | None = None
        self._session_factory: sessionmaker | None = None
        self._initialized = False

    def initialize_db(self) -> None:
        """Initialize the database. Allows db operations to be performed.

        Save module should be instantiated before this function is called.
        """
        if self._initialized:
            return

        # Get the database path
        db_path = save.data_folder_path() / (self._DB_NAME + ".db")

        # Create the database engine
        self._engine = create_engine(f"sqlite:///{db_path}")

        # Create the database tables if they do not exist
        Base.metadata.create_all(self._engine)

        # Create a session maker
        self._session_factory = sessionmaker(bind=self._engine)

        self._initialized = True

    def close_db(self) -> None:
        """Close the database connection."""
        if not self._initialized:
            logger.warning("Tried to close database before it was initialized.")
            return

        cast("Engine", self._engine).dispose()

    def create_session(self) -> Session:
        """Create a new database session."""
        if not self._initialized:
            raise RuntimeError(self._UNINITIALIZED_MSG)

        return cast("sessionmaker", self._session_factory)()


_state = State()

initialize = _state.initialize_db
create_session = _state.create_session
close_db = _state.close_db
