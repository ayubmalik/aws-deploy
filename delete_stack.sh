#!/usr/bin/env bash
declare -A params
declare lastawsresult

deletestack() {
  echo "Deleting stack..."
  exit 1
}

runaws() {
  cmd=${1}
  echo "running 'aws ${cmd}'"
  #awsresult=$(aws ${cmd})
}

declare AppName

read -p "Enter App/StackName: " AppName
LBName="lb-${AppName}"
SecurityGroupName="secgroup-${AppName}"
SubnetName="subnet-${AppName}"

echo "Getting instances"
InstanceIDs=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=${AppName}" | grep INSTANCES | cut -f8)
echo "Instances: ${InstanceIDs}"
if [[ ! -z ${InstanceIDs} ]]; then
  delay=5
  ShuttingDownIDs=${InstanceIDs}
  echo "deregistering instances from loadbalancers"
  aws elb deregister-instances-from-load-balancer --load-balancer-name ${LBName} --instances ${InstanceIDs}
  echo "terminating instances"
  aws ec2 terminate-instances --instance-ids ${InstanceIDs}
  while [[ ! -z ${ShuttingDownIDs} ]]; do
    echo "Waiting ${delay}s for all instances to terminate..."
    sleep ${delay}
    ShuttingDownIDs=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=shutting-down" "Name=tag:Name,Values=${AppName}" | grep INSTANCES | cut -f8)
  done
fi
echo "Checking instance state after termination"
InstanceIDs=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${AppName}" | grep INSTANCES)
echo "Instances: ${InstanceIDs}"

echo "Deleting load balancer"
aws elb delete-load-balancer --load-balancer-name ${LBName}

echo "Getting security group"
SecurityGroupID=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=${SecurityGroupName}" | grep SECURITYGROUPS | cut -f3)
echo "Security group: ${SecurityGroupID}"
if [[ ! -z ${SecurityGroupID} ]]; then
  echo "Deleting security groups"
  aws ec2 delete-security-group --group-id ${SecurityGroupID}
fi

echo "Getting subnet"
SubnetID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=${SubnetName}" | grep SUBNETS | cut -f8)
echo "Subnet: ${SubnetID}"
if [[ ! -z ${SubnetID} ]]; then
  echo "Deleting subnet"
  aws ec2 delete-subnet --subnet-id ${SubnetID}
fi
