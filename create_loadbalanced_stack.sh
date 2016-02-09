#!/usr/bin/env bash
declare -A params
declare lastawsresult

trap rollback SIGINT

rollback() {
  echo
  echo "*** Rolling back ***"
  echo "terminating instances"
  $(aws ec2 terminate-instances --instance-ids ${params[InstanceIDs]})
  sleep 0.5
  echo "deleting security groups"
  $(aws ec2 delete-security-group --group-id ${params[SecurityGroupID]})
  sleep 0.5
  echo "deleting subnet"
  $(aws ec2 delete-subnet --subnet-id ${params[SubnetID]})
  exit 1
}

readparam() {
  name=${1}
  default=${2}
  read -p "Enter ${name}: [${default}] " value
  value=${value:-${default}}
  params[${name}]=${value}
}

runaws() {
  cmd=${1}
  echo "running 'aws ${cmd}'"
  awsresult=$(aws ${cmd})
  if [[ $? -ne 0 ]]; then rollback; fi
}

awsresultfield() {
  pos=${1}
  pattern=${2}
  value=$(echo "${awsresult}" | grep "${pattern}" | cut -f${pos})
  echo ${value}
}

readparam KeyName "aws-keyname"
readparam VPCID "vpc-50274435"
readparam AppName "app01"
readparam LBName "lb-${params[AppName]}"
readparam SecurityGroupName "secgroup-${params[AppName]}"
readparam SecurityGroupPorts "22 80 2552"
readparam SubnetName "subnet-${params[AppName]}"
readparam SubnetCIDR "172.30.9.0/24"
readparam ImageID "ami-bff32ccc"
readparam NumberOfInstances 2

# create subnet and extract id
runaws "ec2 create-subnet --cidr-block ${params[SubnetCIDR]} --vpc-id ${params[VPCID]}"
params[SubnetID]=$(awsresultfield 6)

#tag with name
runaws "ec2 create-tags --resources ${params[SubnetID]} --tags Key=Name,Value=${params[SubnetName]}"

# create security group + tag
runaws "ec2 create-security-group \
  --vpc-id ${params[VPCID]} \
  --group-name ${params[SecurityGroupName]} \
  --description ${params[SecurityGroupName]}"

params[SecurityGroupID]=$(awsresultfield 1)
runaws "ec2 create-tags --resources ${params[SecurityGroupID]} --tags Key=Name,Value=${params[SecurityGroupName]}"

for port in ${params[SecurityGroupPorts]}; do
  runaws "ec2 authorize-security-group-ingress --group-id ${params[SecurityGroupID]} --protocol tcp --port ${port} --cidr 0.0.0.0/0"
done

# TODO add rules for security group

# create instances + tag
runaws "ec2 run-instances \
  --instance-type t2.micro \
  --associate-public-ip-address \
  --key-name ${params[KeyName]} \
  --image-id ${params[ImageID]} \
  --subnet-id ${params[SubnetID]} \
  --security-group-ids ${params[SecurityGroupID]} \
  --count ${params[NumberOfInstances]}"

params[InstanceIDs]=$(awsresultfield 8 INSTANCES)
echo "IDs: ${params[InstanceIDs]}"

# tag instances
runaws "ec2 create-tags --resources ${params[InstanceIDs]} --tags Key=Name,Value=${params[AppName]}"

# create load balancer
runaws "elb create-load-balancer \
   --load-balancer-name ${params[LBName]} \
   --subnets ${params[SubnetID]} \
   --security-groups ${params[SecurityGroupID]} \
   --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80"