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
  value=$(echo ${awsresult} | -f${pos})
  echo ${value}
}

runaws "ec2 describe-instances "
instances=$(echo "$awsresult" | grep INSTANCES | cut -f8)
echo "$instances"

echo

runaws "ec2 describe-subnets "
subs=$(echo "$awsresult" | cut -f8)
echo "$subs"

#aws ec2 describe-instances
