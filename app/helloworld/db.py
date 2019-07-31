"""Sets up our db orm configuration."""

from flask import Flask
from sqlalchemy import create_engine
from sqlalchemy.orm import scoped_session, sessionmaker
from sqlalchemy.ext.declarative import declarative_base
from flask_marshmallow import Marshmallow
from config import CONFIG_FILE

app = Flask(__name__)

engine = create_engine(CONFIG_FILE['sql_conn_string'], pool_recycle=280, pool_size=5)
db_session = scoped_session(sessionmaker(autocommit=False,
                                         autoflush=False,
                                         bind=engine))

ma = Marshmallow(app)

Base = declarative_base()
Base.query = db_session.query_property()


def init_db():
    """Ensure all of my model's schemas are created."""
    import password_sentinel.models
    Base.metadata.create_all(bind=engine)
