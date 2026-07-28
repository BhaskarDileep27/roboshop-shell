#!/bin/bash
set -e

AMI="ami-0220d79f3f480ecf5" # this keeps on changing
SG_ID="sg-0e75a9a19ca1ccce6" # replace with your SG ID
AWS_REGION="${AWS_REGION:-us-east-1}"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "web")
ZONE_ID="Z10151982EVZUHG3VSVN6" # replace your zone ID
DOMAIN_NAME="dileep.sbs"

if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "AWS credentials are not configured."
    echo "On your machine, run: aws configure"
    echo "On EC2, attach an IAM role with AmazonEC2FullAccess"
    exit 1
fi

for i in "${INSTANCES[@]}"
do
    if [ "$i" == "mongodb" ] || [ "$i" == "mysql" ] || [ "$i" == "shipping" ]
    then
        INSTANCE_TYPE="t3.small"
    else
        INSTANCE_TYPE="t3.micro"
    fi

    IP_ADDRESS=$(aws ec2 run-instances \
        --region "$AWS_REGION" \
        --image-id "$AMI" \
        --instance-type "$INSTANCE_TYPE" \
        --security-group-ids "$SG_ID" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" \
        --query 'Instances[0].PrivateIpAddress' \
        --output text)

    echo "$i: $IP_ADDRESS"
done