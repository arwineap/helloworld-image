"""Set up the app."""

from flask import Flask, send_from_directory
from flask_migrate import Migrate
from helloworld.app import helloworld_app
from helloworld.db import Base

application = Flask(__name__)
application.register_blueprint(helloworld_app, url_prefix='/')

migrate = Migrate(application, Base)


@application.route('/static/<path:path>', methods=['GET'])
def static_view():
    """Set a route for static assets."""
    # TODO replace this with nginx
    return send_from_directory('static', path)


if __name__ == '__main__':
    application.run(port=5000, host='0.0.0.0')
