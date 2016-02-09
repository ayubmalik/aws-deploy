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
if [[ ${InstanceIDs} != "" ]]; then
  delay=5
  TerminatedIDs=
  echo "deregistering instances from loadbalancers"
  aws elb deregister-instances-from-load-balancer --load-balancer-name ${LBName} --instances ${InstanceIDs}
  echo "terminating instances"
  aws ec2 terminate-instances --instance-ids ${InstanceIDs}
  while [[ -z ${TerminatedIDs} ]]; do
    echo "Waiting ${delay}s for instances to terminate..."
    sleep ${delay}
    TerminatedIDs=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=terminated" "Name=tag:Name,Values=${AppName}" | grep INSTANCES | cut -f8)
  done
fi

echo "Deleting load balancer"
aws elb delete-load-balancer --load-balancer-name ${LBName}

echo "Getting security group"
SecurityGroupID=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=${SecurityGroupName}" | grep SECURITYGROUPS | cut -f3)
echo "Security group: ${SecurityGroupID}"
if [[ ${SecurityGroupID} != "" ]]; then
  echo "Deleting security groups"
  aws ec2 delete-security-group --group-id ${SecurityGroupID}
fi

echo "Getting subnet"
SubnetID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=${SubnetName}" | grep SUBNETS | cut -f8)
echo "Subnet: ${SubnetID}"
if [[ ${SubnetID} != "" ]]; then
  echo "Deleting subnet"
  aws ec2 delete-subnet --subnet-id ${SubnetID}
fi
