"""Configure settings to be used by the app."""

import os
import json

CONFIG_FILE = None
if os.getenv('CONFIG_FILE'):
    CONFIG_FILE = json.load(open(os.getenv('CONFIG_FILE')))

# If kms is configured, decrypt all of the configs
if 'kms' in CONFIG_FILE.keys():
    import kms
    for secret_config in CONFIG_FILE['kms']:
        CONFIG_FILE[secret_config] = kms.decrypt(CONFIG_FILE[secret_config])
