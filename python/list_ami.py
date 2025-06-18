import boto3
from config.load_config import get_aws_config

config = get_aws_config()

session = boto3.Session(
    aws_access_key_id = config['aws_access_key_id'],
    aws_secret_access_key = config['aws_secret_access_key'],
    region_name = config['region_name']
)

ami = session.client('ec2')

def getAmazonLinux2Ami(region, distro):
    
    if distro == "amazon":
        owners=['amazon']  # Amazon-owned images
        filters=[
            {'Name': 'name', 'Values': ['amzn2-ami-hvm-*-x86_64-gp2']},
            {'Name': 'state', 'Values': ['available']},
            {'Name': 'root-device-type', 'Values': ['ebs']},
            {'Name': 'virtualization-type', 'Values': ['hvm']}
        ]
    elif distro == "ubuntu":
        owners=['596061404617']  # Ubuntu images
        filters =[
            {'Name': 'name', 'Values': ['Ubuntu_22.04-x86_64-SQL_2022_Express-*']},
            {'Name': 'state', 'Values': ['available']}
        ]
    
    ami_list = ami.describe_images(Owners=owners, Filters=filters)
    # ami_list = ami.describe_images(
    #     Owners=['amazon'],  # Amazon-owned images
    #     Filters=[
    #         {'Name': 'name', 'Values': ['amzn2-ami-hvm-*-x86_64-gp2']},
    #         {'Name': 'state', 'Values': ['available']},
    #         {'Name': 'root-device-type', 'Values': ['ebs']},
    #         {'Name': 'virtualization-type', 'Values': ['hvm']}
    #     ]
    # )
    
    #amazon_image = ami_list['Images']
    
    # Sort images by creation date descending
    amazon_images = sorted(ami_list['Images'], key=lambda x: x['CreationDate'], reverse=True)
    latest_image = amazon_images[0]['ImageId']
    if latest_image:
        return latest_image
        #print(latest_image)
    else:
        return None
    
getAmazonLinux2Ami(config['region_name'], 'amazon')