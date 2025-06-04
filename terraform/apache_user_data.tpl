#!/bin/bash

export DB_HOST="${db_host}"
export DB_PORT="3306"

yum update -y

# Install Docker
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user

# Install Apache and PHP
sudo yum update -y
sudo yum install -y httpd php php-cli php-common php-mysqlnd

# Start and enable Apache
sudo systemctl start httpd
sudo systemctl enable httpd

# Create a test HTML page
echo "OK" | sudo tee /var/www/html/index.html

# Create a PHP info page
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php
