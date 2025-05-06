import json

#gettting AWS configuration and credential path
def get_aws_config(config_path='config/aws_config.json'):
    with open(config_path) as path:
        config = json.load(path)
    return config