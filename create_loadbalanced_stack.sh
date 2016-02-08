#!/usr/bin/env bash
declare -A params
declare lastawsresult

rollback() {
  echo "Rolling back..."
  # delete instances
  # delete subnets
  # delete loadbalancer
  # delete securitgroups
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
readparam AppName "app01"
readparam VPCID "vpc-50274435"
readparam LBName "lb_${params[AppName]}"
readparam SecurityGroupName "sg_${params[AppName]}"
readparam SubnetName "subnet_${params[AppName]}"
readparam SubnetCIDR "172.30.9.0/24"
readparam ImageID "ami-bff32ccc"
readparam NumberOfInstances 2

# create subnet and extract id
runaws "ec2 create-subnet --cidr-block ${params[SubnetCIDR]} --vpc-id ${params[VPCID]}"
params[SubnetID]=$(awsresultfield 6)

echo "Created Subnet:  ${params[SubnetID]}"
#tag with name
runaws "ec2 create-tags --resources ${params[SubnetID]} --tags Key=Name,Value=${params[SubnetName]}"

# create security group + tag
runaws "ec2 create-security-group \
  --group-name ${params[SecurityGroupName]} \
  --description ${params[SecurityGroupName]}"

params[SecurityGroupID]=$(awsresultfield 1)
runaws "ec2 create-tags --resources ${params[SecurityGroupID]} --tags Key=Name,Value=${params[SecurityGroupName]}"

exit 0
# create instances
runaws "ec2 run-instances \
  --instance-type t2.micro \
  --associate-public-ip-address \
  --key-name ${params[KeyName]} \
  --image-id ${params[ImageID]} \
  --subnet-id ${params[SubnetID]} \
  --count ${params[NumberOfInstances]}"

params[InstanceIDs]=$(awsresultfield 8 INSTANCES)
echo "Created Instances: ${params[InstanceIDs]}"

# tag instances
runaws "ec2 create-tags --resources ${params[InstanceIDs]} --tags Key=Name,Value=${params[AppName]}"
