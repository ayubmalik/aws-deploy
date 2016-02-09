#!/usr/bin/env bash
declare awsresult

runaws() {
  cmd=${1}
  echo "running 'aws ${cmd}'"
  awsresult=$(aws ${cmd} | tr -s ' ')
  if [[ $? -ne 0 ]]; then rollback; fi
}

awsresultfield() {
  pos=${1}
  pattern=${2}
  value=$(echo "${awsresult}" | grep "${pattern}" | cut -f${pos})
  echo ${value}
}

runaws "ec2 describe-subnets"
result=$(awsresultfield 8)
echo $result

runaws "elb create-load-balancer \
   --load-balancer-name lb-spike-01 \
   --subnets subnet-7b5c270c \
   --security-groups sg-f69d5f92 \
   --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80"


echo $awsresult
