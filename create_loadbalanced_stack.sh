#!/usr/bin/env bash
declare -A params
declare lastawsresult

rollback() {
  echo "Rolling back..."
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
  value=$(echo ${awsresult} | cut -d' ' -f${pos})
  echo ${value}
}

readparam AppName "app01"
readparam VPCID "vpc-50274435"
readparam LBName "lb_${params[AppName]}"
readparam SecurityGroupName "sg_${params[AppName]}"
readparam SubnetName "subnet_${params[AppName]}"
readparam SubnetCIDR "172.30.9.0/24"
readparam ImageID "ami-bff32ccc"
readparam NumberOfInstances 2
readparam KeyName "aws-keyname"

# create subnet and extract id
runaws "ec2 create-subnet --cidr-block ${params[SubnetCIDR]} --vpc-id ${params[VPCID]}"
params[SubnetID]=$(awsresultfield 6)

#tag with name
runaws "ec2 create-tags --resources ${params[SubnetID]} --tags Key=Name,Value=${params[SubnetName]}"

exit 0
runaws "ec2 run-instances \
  --instance-type t2.micro \
  --associate-public-ip-address \
  --key-name ${params[KeyName]} \
  --image-id ${params[ImageID]} \
  --subnet-id ${params[SubnetID]} \
  --count ${params[NumberOfInstances]}"
