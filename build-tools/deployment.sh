#!/bin/bash

while getopts i:u:m:s:d:r: flag
do
    case "${flag}" in
        i) server_ip=${OPTARG};; # IP address of the server
        u) server_username=${OPTARG};; # SSH user of the server
        m) mode=${OPTARG};; # prod/staging
        s) ssh_key=${OPTARG};; # ssh key
        d) base_directory=${OPTARG};; # base directory
        r) serverBaseDirectory=${OPTARG};; # server base directory
    esac
done

if [ -z $mode ];
then
    echo "Please provide application mode using parameter '-m'. The mode can either be 'prod' or 'staging'"
    exit 1
fi

if [ -z $server_ip ];
then
    echo "Please provide ip address of the server using the parameter '-i'"
    exit 1
fi

if [ -z $server_username ];
then
    echo "Please provide the ssh username of the server using the parameter '-u'"
    exit 1
fi

if [ -z $ssh_key ];
then
    echo "Please provide the ssh key path using the parameter '-s'"
    exit 1
fi

if [ -z $base_directory ];
then
    echo "Please provide the base directory path using the parameter '-d'"
    exit 1

if [ -z $serverBaseDirectory ];
then
    echo "Please provide the server base directory path using the parameter '-r'"
    exit 1
fi
fi

echo "Running deployment script for application mode '$mode' from directory '$base_directory' to server '$server_username@$server_ip' with remote base directory '$serverBaseDirectory'"
# Server variables
server="$server_username@$server_ip" # Server info
localBaseDirectory=$base_directory # Base directory on the local machine

echo "Deploying application to server $server"

# 1. Stop the docker container in ~/iam directory
echo "Stopping the docker container"
ssh -i $ssh_key $server "cd $serverBaseDirectory && docker compose down"

# 2. Copy the docker compose directory to the server
echo "Copying the docker compose file to the server"
scp -i $ssh_key $localBaseDirectory/docker-compose.production.yml  $server:$serverBaseDirectory/docker-compose.temp.yml

# 3. Copy the wp-content directory of wordpress
echo "Copying the wp-content directory to the server"
scp -i $ssh_key -r $localBaseDirectory/app/wp-content $server:$serverBaseDirectory/app/wp-content


echo "Moving the docker-compose file to the correct location"
ssh -i $ssh_key $server "sudo mv $serverBaseDirectory/docker-compose.temp.yml $serverBaseDirectory/docker-compose.yml"

# Copy env file if it exists
if [ -f "$localBaseDirectory/.env" ]; then
    echo "Copying .env file from $localBaseDirectory to $serverBaseDirectory"
    scp -i $ssh_key $localBaseDirectory/.env $server:$serverBaseDirectory/.env
else
    echo ".env file does not exist in $base_directory"
fi

# 4. Start the docker container in ~/iam directory
echo "Starting the docker container"
ssh -i $ssh_key $server "cd $serverBaseDirectory && docker compose up -d"



