"""Setup helloworld controller."""

from flask import Blueprint, request, render_template, current_app
from helloworld.models import Image, ImageSchema
from config import CONFIG_FILE
from helloworld.db import db_session
from sqlalchemy.exc import SQLAlchemyError
from werkzeug.utils import secure_filename
import botocore
import time
import boto3
import sqlalchemy

helloworld_app = Blueprint('helloworld_app', __name__)
s3 = boto3.client('s3')


@helloworld_app.route('', methods=['GET'])
def root_get():
    """Accept GET request with form to add an image."""
    img_data, err = get_img_data()
    if err:
        return render_template("helloworld/error.html", error_message=img_data["error_message"]), 500
    if img_data == {}:
        # if img_data is nothing it means our database does not yet have any entries.
        return render_template("helloworld/view.html", img_data=img_data, title="Hello world! %d" % time.time())
    return render_template("helloworld/view.html", img_domain=CONFIG_FILE['img_domain'], img_data=img_data, title="Hello world! %d" % time.time())


@helloworld_app.route('', methods=['POST'])
def root_post():
    """Route will handle adding new images."""
    # Verify img_file is defined in POST and it's not an empty filename
    if "img_file" not in request.files or request.files["img_file"].filename == "":
        return render_template("helloworld/error.html", error_message="img_file missing."), 500
    img_file = request.files["img_file"]
    # Verify img_title is defined in POST and is not empty
    if "img_title" not in request.form or request.form["img_title"] == "":
        return render_template("helloworld/error.html", error_message="img_title missing."), 500
    img_title = request.form['img_title']
    # Sanitize user input with secure_filename
    # https://werkzeug.palletsprojects.com/en/0.15.x/utils/
    img_file.filename = secure_filename(img_file.filename)
    if s3_upload_img(img_file, CONFIG_FILE['s3_bucket'], img_file.content_type):
        # Upload was successful, add to database
        img_upload = Image(img_title, img_file.filename)
        db_session.add(img_upload)
        try:
            db_session.commit()
            img_id = img_upload.id
            db_session.close()
        except SQLAlchemyError as exception:
            db_session.rollback()
            db_session.close()
            return render_template("helloworld/error.html", error_message=str(exception)), 500
    else:
        # S3 upload has failed
        return render_template("helloworld/error.html", error_message="s3 upload has failed")
    # Render the POST body with the new image included
    img_data, err = get_img_data(img_id)
    if err:
        # Getting new image has failed
        return render_template("helloworld/error.html", error_message=img_data["error_message"]), 500
    return render_template("helloworld/view.html", img_data=img_data, img_domain=CONFIG_FILE['img_domain'], title="Hello world! %d" % time.time())


@helloworld_app.route('/health', methods=['GET'])
def healthcheck():
    """Run healthcheck on the app for the load balancer."""
    system_health = {}
    system_health['mysql'] = False
    system_health['s3'] = False
    # check mysql
    try:
        db_session.query(Image).count()
        system_health['mysql'] = True
    except sqlalchemy.exc.OperationalError:
        system_health['mysql'] = False
    # check s3
    try:
        if s3.head_bucket(Bucket=CONFIG_FILE['s3_bucket']):
            system_health['s3'] = True
        else:
            system_health['s3'] = False
    except botocore.exceptions.ClientError:
        system_health['s3'] = False
    # check if any healthchecks returned True
    if all(health is True for health in system_health.values()):
        return render_template("helloworld/health.html", status_message=system_health, title="OK")
    return render_template("helloworld/health.html", status_message=system_health, title="Unhealthy"), 500


def get_img_data(img_id=None):
    """
    Get img details.

    This returns a tuple of (results, error)
    If error is true you can get the errormessage from results["error_message"]
    """
    img_schema = ImageSchema()
    if img_id:
        try:
            image_data = db_session.query(Image).get(img_id)
        except SQLAlchemyError as exception:
            db_session.rollback()
            db_session.close()
            return {'status': 'ERROR', 'error_message': str(exception)}, True
    else:
        try:
            image_data = db_session.query(Image).order_by(Image.created_at.desc()).first()
        except SQLAlchemyError as exception:
            db_session.rollback()
            db_session.close()
            return {'status': 'ERROR', 'error_message': str(exception)}, True
    db_session.close()
    return img_schema.dump(image_data).data, False


def s3_upload_img(file, bucket, content_type):
    """Upload file to s3."""
    try:
        s3.upload_fileobj(file, bucket, file.filename, ExtraArgs={"ACL": "public-read", "ContentType": file.content_type})
    except botocore.exceptions.ClientError as e:
        current_app.logger.error(str(e))
        return False
    return True
