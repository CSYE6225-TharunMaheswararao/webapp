import boto3
import urllib.parse
import configparser
import os

config = configparser.ConfigParser()
db_path = os.path.join(os.path.dirname(__file__), 'app.config')
config.read(db_path)

session = boto3.Session()
credentials = session.get_credentials()
if not credentials:
    raise Exception("AWS Credentials are missing")


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

def get_ssm_param(name):
    ssm = boto3.client('ssm', region_name="us-east-1")
    response = ssm.get_parameter(Name=name, WithDecryption=True)
    return response['Parameter']['Value']

# Load S3 Bucket from AWS SSM
S3_BUCKET = get_ssm_param("/webapp/s3_bucket")