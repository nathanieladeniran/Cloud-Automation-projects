import boto3
import json
from botocore.exceptions import ClientError

#gettting AWS configuration and credential path
def get_aws_config(config_path='config/aws_config.json'):
    with open(config_path) as path:
        config = json.load(path)
    return config

config = get_aws_config()

session = boto3.Session(
    aws_access_key_id = config['aws_access_key_id'],
    aws_secret_access_key = config['aws_secret_access_key'],
    region_name = config['region_name']
)
ec2 = session.client('ec2')

response = ec2.describe_instances()

# Note if on AWS lambda  just use 
# ec2 = boto3.client('ec2')
# response = ec2.describe_instances()  #because you already logged in and you don need any credential

#list instance in array
def returnInstancesObject():
    return{
        'statusCode' : 200,
        'body' : response
    }

#list instance with specifics like instance name, Instance ID
def listInstances():
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            print (f"Instance ID: {instance['InstanceId']}")

#list instance using tags            
def listInstancesWithFIlter():
    filterResponse = ec2.describe_instances(Filters=[{'Name': 'tag:AutoStart', 'Values': ['True']}]) #Look for EC2 instances with a tag key of AutoStart and Value True
    for reservation in filterResponse['Reservations']:
        for instance in reservation['Instances']:
            print (f"Instance ID: {instance['InstanceId']}")

# Create/Launch an instance
def createInstance():    
    ec2_resource = session.resource('ec2')
    instances = ec2_resource.create_instances(
        ImageId='ami-000e875cc81ac2df0',  # Amazon Linux 2 AMI for us-east-1
        MinCount=1,
        MaxCount=1,
        InstanceType='t2.micro',
        KeyName='S-key',  # Replace with your EC2 key pair name
        SecurityGroupIds=['sg-00b0d9396f5740072'],  # Replace with your security group ID
        TagSpecifications=[
            {
                'ResourceType': 'instance',
                'Tags': [
                    {'Key': 'Name', 'Value': 'WebInstance'},
                    {'Key': 'Environment', 'Value': 'Dev'},
                    {'Key': 'AutoStart', 'Value': 'True'}
                ]
            },
            {
                'ResourceType': 'volume',
                'Tags': [
                    {'Key': 'Name', 'Value': 'WebVolume'},
                    {'Key': 'Environment', 'Value': 'Dev'}
                ]
            }
        ]
    )

    print("Launched EC2 Instance with ID:", instances[0].id, "Waiting for it to be running")
    
    # Waiting for instance to be running
    
    newInstance = instances[0]
    newInstance.wait_until_running()
    newInstance.reload()
    print(f"Instance {instances[0].id} now running")
    
    # Allocating and Associating ELastic IP
    try:
        # Allocating IP
        allocated_eip = ec2.allocate_address(Domain='vpc')
        
        #Associating Elastic IP
        response = ec2.associate_address(AllocationId=allocated_eip['AllocationId'], InstanceId=newInstance.id)
        # print(response)
        print(f"Elastic IP associated, the associated IP is: {allocated_eip['PublicIp']}, Allocation Id is: {allocated_eip['AllocationId']}, Associated with instance {newInstance.id}")
        
    except ClientError as e: 
        print(e)
    
    # Tagging Elastic IP
    ec2.create_tags(
        Resources=[allocated_eip['AllocationId']],
        Tags=[
            {'Key': 'Name', 'Value': 'Webeip'},
            {'Key': 'Environment', 'Value': 'dev'}
        ]
    )
    print("Elastic IP tagged successfully>>>>>>>>>>>>>>>>.")
    print("Instance provisioning complete>>>>>>>>>>>>>>>>.")
           
def main():
     
     while True:
        print("\n📋 Choose a Task to Perform:")
        print("1️⃣  List EC2 All Instances")
        print("2️⃣  List instance with Tag AutoStart")
        print("3️⃣  Create Instance")
        
        task = input("\n Select an operation: ")
        
        if task == "1":
            print(listInstances())
        elif task == "2":
            print(listInstancesWithFIlter())
        elif task == "3":
            print(createInstance())
        else:
            print("invalid number selected")
        
# print(listInstancesWithFIlter())
if __name__ == "__main__":
    main()