"""Setup the db models for our application."""

from sqlalchemy import Column, Integer, DateTime, String
from datetime import datetime
from helloworld.db import Base, ma


class Image(Base):
    """Define our image table, to track our latest images and paths."""

    __tablename__ = 'images'
    id = Column(Integer, primary_key=True)
    img_title = Column(String(256))
    s3_path = Column(String(128))
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow())

    def __init__(self, img_title, s3_path):
        """Define our image information."""
        self.img_title = img_title
        self.s3_path = s3_path
        self.created_at = datetime.utcnow()

    def __repr__(self):
        """Return a nice print object."""
        return '<Image %s %s %s>' % (self.id, self.img_title, self.created_at)


class ImageSchema(ma.Schema):
    """Setup marshmellow serializer."""

    created_at = ma.DateTime()

    class Meta:
        """Setup marshmellow serializer."""

        fields = ('id', 'img_title', 's3_path', 'created_at')
        datetimeformat = "%Y-%m-%dT%H:%M:%S"
