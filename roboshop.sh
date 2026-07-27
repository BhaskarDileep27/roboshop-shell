#!/bin/bash

set -e

AMI=ami-0220d79f3f480ecf5 # this keeps on changing
SG_ID=sgr-07b0a52a1ce880591 # replace with your SG ID
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "web" "payment" "dispatch" "shipping")
ZONE_ID=Z10151982EVZUHG3VSVN6 # replace your zone ID
DOMAIN_NAME="dileep.sbs"

for i in "${INSTANCES[@]}"
do
    if [[ "$i" == "mongodb" || "$i" == "mysql" || "$i" == "shipping" ]]; then
        INSTANCE_TYPE="t3.small"
    else
        INSTANCE_TYPE="t2.micro"
    fi

    echo "Creating instance for $i..."
    IP_ADDRESS=$(aws ec2 run-instances \
        --image-id "$AMI" \
        --instance-type "$INSTANCE_TYPE" \
        --security-group-ids "$SG_ID" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" \
        --query 'Instances[0].PrivateIpAddress' \
        --output text)

    if [[ -z "$IP_ADDRESS" ]]; then
        echo "Unable to get private IP for $i. Skipping Route53 update."
        continue
    fi

    echo "$i: $IP_ADDRESS"

    CHANGE_BATCH=$(cat <<EOF
{
  "Comment": "Creating a record set for cognito endpoint",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$i.$DOMAIN_NAME",
        "Type": "A",
        "TTL": 1,
        "ResourceRecords": [
          {
            "Value": "$IP_ADDRESS"
          }
        ]
      }
    }
  ]
}
EOF
)

    aws route53 change-resource-record-sets \
        --hosted-zone-id "$ZONE_ID" \
        --change-batch "$CHANGE_BATCH"
done