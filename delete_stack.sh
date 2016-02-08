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

AppName=
read -p "Enter App/StackName: " AppName
LBName="lb_${AppName}"
SecurityGroupName="sg_${AppName}"
SubnetName="subnet_${AppName}"

InstanceIDs=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=${AppName}" | grep INSTANCES | cut -f8)
SecurityGroupID=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=${SecurityGroupName}" | grep SECURITYGROUPS | cut -f3)

echo  "Instances ${InstanceIDs}"
echo  "Subnet ${SecurityGroupID}"
