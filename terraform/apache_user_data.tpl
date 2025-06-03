#!/bin/bash
yum update -y

# Install Docker
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user

# Install Apache (httpd)
yum install -y httpd
systemctl start httpd
systemctl enable httpd
