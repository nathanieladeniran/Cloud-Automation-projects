import boto3
from datetime import datetime
from config.load_config import get_aws_config

config = get_aws_config()

session = boto3.Session(
    aws_access_key_id = config['aws_access_key_id'],
    aws_secret_access_key = config['aws_secret_access_key'],
    region_name = config['region_name']
)

ec2 = session.client('ec2')

def start_stop_instances(state):
    
    response = ec2.describe_instances()

    instance_ids = [] # creating array that will be a collecton of all IDS fetched
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_ids.append(instance['InstanceId'])

    print(instance_ids)
    if state == "Start":
        ec2.start_instances(InstanceIds=instance_ids)
        print(f"Started instances: {instance_ids}")
    elif state == "Stop":
        ec2.stop_instances(InstanceIds=instance_ids)
        print(f"Stopped instances: {instance_ids}")
    elif state == "Reboot":
        ec2.reboot_instances(InstanceIds=instance_ids)
        print(f"Rebooting instances: {instance_ids}")
    else:
        print("Invalid")
        

def main():
    
    while True:
        print("\n Input an action \n Type Start to start an instance or \n Type Stop to stop an instance or \n Type Reboot to reboot an instance")  
        
        action = input("\n Type an action: ")
        
        if action == "Start":
            start_stop_instances("Start")
        elif action == "Stop":
            start_stop_instances("Stop")
        elif action == "Reboot":
            start_stop_instances("Reboot")
        else:
            print("Invalid action supplied")
          
if __name__ == "__main__":
    main()