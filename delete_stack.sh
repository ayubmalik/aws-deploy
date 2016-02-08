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
LBName="lb_${AppName}"
SecurityGroupName="sg_${AppName}"
SubnetName="subnet_${AppName}"

InstanceIDs=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=${AppName}" | grep INSTANCES | cut -f8)
SecurityGroupID=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=${SecurityGroupName}" | grep SECURITYGROUPS | cut -f3)
SubnetID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=${SubnetName}" | grep SUBNETS | cut -f8)

echo  "Instances ${InstanceIDs}"
echo  "SecurityG ${SecurityGroupID}"
echo  "Subnet ${SubnetID}"

echo "terminating instances"
aws ec2 terminate-instances --instance-ids ${InstanceIDs}
delay=5
PendingIDs=
while [[ -z "${PendingIDs}" ]]; do
  echo "Waiting ${delay}s for instances to terminate..."
  sleep ${delay}
  PendingIDs=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=terminated" "Name=tag:Name,Values=${AppName}" | grep INSTANCES | cut -f8)
done

echo "deleting security groups"
aws ec2 delete-security-group --group-id ${SecurityGroupID}
echo "deleting subnet"
aws ec2 delete-subnet --subnet-id ${SubnetID}
