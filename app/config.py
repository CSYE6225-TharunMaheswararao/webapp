import urllib.parse
import configparser
import os

config = configparser.ConfigParser()
db_path = os.path.join(os.path.dirname(__file__), 'app.config')
config.read(db_path)


def get_config(app_config):
    keys = map(lambda x: x.upper(), list(app_config.keys()))
    connection_string = {}
    for key in keys:
        connection_string[key] = os.environ.get(key, app_config[key])
    return connection_string


def get_db_uri():
    config_database = config['DATABASE']
    database = get_config(config_database)
    db_uri = "mysql+pymysql://{0}:{1}@{2}/{3}".format(
        urllib.parse.quote_plus(database['DB_USERNAME']),
        urllib.parse.quote_plus(database['DB_PASSWORD']),
        urllib.parse.quote_plus(database['DB_HOST']),
        urllib.parse.quote_plus(database['DB_NAME'])
    )
    return db_uri

# S3 Configuration
s3_config = get_config("S3")
S3_BUCKET = s3_config.get("S3_BUCKET", None)
AWS_REGION = s3_config.get("AWS_REGION", "us-east-1")