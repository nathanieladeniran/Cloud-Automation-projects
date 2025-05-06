import boto3
from datetime import datetime
from config.load_config import get_aws_config

config = get_aws_config()

session = boto3.Session(
    aws_access_key_id = config['aws_access_key_id'],
    aws_secret_access_key = config['aws_secret_access_key'],
    region_name = config['region_name']
)