#!/bin/bash

AWS_DEV_INSTANCE_ID=i-07e3937df30615e40
AWS_GYB_INSTANCE_ID=i-08cb4903655d86854
SSH_LINE_DEV=21
SSH_LINE_GYB=15
INSTANCE_ID=0
SSH_LINE=0

function start_aws_instance() {
  aws ec2 start-instances --instance-id $INSTANCE_ID
}

function stop_aws_instance() {
  aws ec2 stop-instances --instance-id $INSTANCE_ID
}

function replace_hosts_ip() {
  ip=$(aws ec2 describe-instances --instance-ids ${INSTANCE_ID} --query 'Reservations[].Instances[].PublicIpAddress' | jq '.[-0]')
  echo "Server IP: ${ip}"
  echo "Updating /.ssh/config ip"
  sudo sed -i '' "${SSH_LINE}s/.*/ Hostname ${ip//\"}/" ~/.ssh/config
  if [ "$SSH_LINE" = "$SSH_LINE_DEV" ]; then
    echo "Updating /etc/hosts ip"
    sudo sed -i '' "$ s|[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}|${ip//\"}|" /etc/hosts
  fi
}

# usage
# remoteenv stop|start|refresh
function awscode() {
  if [ $# -eq 0 ]; then
    echo "illegal number of parameters"
    return
  fi

  if [ "$2" = 'gyb' ]
  then
    echo "working with GYB instance"
    INSTANCE_ID=$AWS_GYB_INSTANCE_ID
    SSH_LINE=$SSH_LINE_GYB
  else
    echo "working with DEV instance"
    INSTANCE_ID=$AWS_DEV_INSTANCE_ID
    SSH_LINE=$SSH_LINE_DEV
  fi

  # stop instance
  if [ "$1" = 'stop' ]; then
    echo "Stoping the AWS instance"
    stop_aws_instance
    echo "AWS instance has been stopped successfully"
    return
  fi

  # start AWS instance
  if [ "$1" = 'start' ]; then
    echo "Starting AWS instance"
    start_aws_instance
    replace_hosts_ip
    return
  fi

  # update AWS instance IP
  if [ "$1" = 'refresh' ]; then
    replace_hosts_ip
    return
  fi
}
