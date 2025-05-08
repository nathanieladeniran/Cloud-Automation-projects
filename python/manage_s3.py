import boto3
from config.load_config import get_aws_config
from botocore.exceptions import ClientError
import logging
import uuid


config = get_aws_config()

# Create a new session
session = boto3.Session(
    aws_access_key_id=config['aws_access_key_id'],
    aws_secret_access_key=config['aws_secret_access_key'],
)
bucket_name = None

def createBucket(bucket_name,  region=None):
    try:
        region = region or config['region_name']
        bucket_name = bucket_name or f"new-bucket-{uuid.uuid4()}"

        if region == 'us-east-1':
            s3 = session.client('s3', region_name=region)
            response = s3.create_bucket(Bucket=bucket_name)
        else:
            s3 = session.client('s3', region_name=region)
            response = s3.create_bucket(
                Bucket=bucket_name,
                CreateBucketConfiguration={'LocationConstraint': region}
            )

        print("✅ Bucket created successfully:", bucket_name)
        return True

    except ClientError as e:
        logging.error("❌ AWS Error: %s", e)
        return False
    except Exception as e:
        logging.error("❌ General Error: %s", e)
        return False

# List all buckets
def listBucket():
    session = boto3.Session(
    aws_access_key_id = config['aws_access_key_id'],
    aws_secret_access_key = config['aws_secret_access_key'],
    region_name = config['region_name']
)
    s3 = session.client('s3')
    bucket_list = s3.list_buckets()
    print(bucket_list)
    
# List buckets with filter
def listBucketWithFilter(bucket_name):
    s3 = session.client('s3')
    bucket_list = s3.list_buckets()
    for bucket in bucket_list['Buckets']:
        if bucket['Name'] == bucket_name:
            print(f"✅ Found bucket: {bucket}")

def main():
    
    while True:
        print("\n You can Select an action to perform in S3 bucket")
        
        print('\n Press 1 to create Bucket')
        print('\n Press 2 to list Bucket')
        
        selected_action = input("\n Choose your option: ")
        
        if selected_action == "1":
            createBucket(bucket_name)
        elif selected_action == "2":
            listBucket()
        else:
            print("Invalid action chosen")

if __name__ == "__main__":
    main()