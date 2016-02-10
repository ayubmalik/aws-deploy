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
declare Delay
read -p "Enter App/StackName: " AppName
LBName="lb-${AppName}"
SecurityGroupName="secgroup-${AppName}"
SubnetName="subnet-${AppName}"
Delay=5
echo "Getting instances"
InstanceIDs=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=${AppName}" | grep INSTANCES | cut -f8)
echo "Instances: ${InstanceIDs}"
if [[ ! -z ${InstanceIDs} ]]; then
  TerminatedIDs=
  echo "deregistering instances from loadbalancers"
  aws elb deregister-instances-from-load-balancer --load-balancer-name ${LBName} --instances ${InstanceIDs}
  echo "terminating instances"
  aws ec2 terminate-instances --instance-ids ${InstanceIDs}
  while [[ ${TerminatedIDs} != ${InstanceIDs} ]]; do
    echo "Waiting ${Delay}s for all instances to terminate. Currently terminated: ${TerminatedIDs}"
    sleep ${Delay}
    TerminatedIDs=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=terminated" "Name=tag:Name,Values=${AppName}" | grep INSTANCES | cut -f8)
  done
fi
echo "Checking instance state after termination"
InstanceStates=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${AppName}" | grep 'STATE\t')
echo "Instance states: ${InstanceStates}"

echo "Deleting load balancer"
aws elb delete-load-balancer --load-balancer-name ${LBName}

NetworkInterfaceIDs=notempty
while [[ ! -z ${NetworkInterfaceIDs} ]]; do
  echo "Waiting ${Delay}s for LB network interfaces to be released"
  sleep ${Delay}
  NetworkInterfaceIDs=$(aws ec2 describe-network-interfaces --filters "Name=description,Values=ELB ${LBName}" | grep NETWORKINTERFACES | cut -f5)
  echo "Network interfaces: ${NetworkInterfaceIDs}"
done

exit 0
echo "Getting security group"
SecurityGroupID=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=${SecurityGroupName}" | grep SECURITYGROUPS | cut -f3)
echo "Security group: ${SecurityGroupID}"
if [[ ! -z ${SecurityGroupID} ]]; then
  aws ec2 delete-security-group --group-id ${SecurityGroupID}
fi

echo "Getting subnet"
SubnetID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=${SubnetName}" | grep SUBNETS | cut -f8)
echo "Subnet: ${SubnetID}"
if [[ ! -z ${SubnetID} ]]; then
  echo "Deleting subnet"
  aws ec2 delete-subnet --subnet-id ${SubnetID}
fi
