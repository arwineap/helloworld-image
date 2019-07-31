"""Configure settings to be used by the app."""

import os
import json

CONFIG_FILE = None
if os.getenv('CONFIG_FILE'):
    CONFIG_FILE = json.load(open(os.getenv('CONFIG_FILE')))
