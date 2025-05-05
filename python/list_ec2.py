import boto3


session = boto3.Session(
    aws_access_key_id = 'AKIARRBIN34MDLV4UNNE',
    aws_secret_access_key = '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',
    region_name= 'us-east-1',
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

def createInstance():
    # Launch an instance
    ec2 = session.resource('ec2')
    instances = ec2.create_instances(
        ImageId='ami-000e875cc81ac2df0',  # Amazon Linux 2 AMI for us-east-1
        MinCount=1,
        MaxCount=1,
        InstanceType='t2.micro',
        KeyName='S-key',  # Replace with your EC2 key pair name
        SecurityGroupIds=['sg-00b0d9396f5740072'],  # Replace with your security group ID
    )
    print("Launched EC2 Instance with ID:", instances[0].id)

            
print(listInstancesWithFIlter())
# if __name__ == "__main__":
#     main()