#!/bin/bash

function parse_options() {
  key_name=
  image_id=
  subnet_id=subnet-7b5c270c #eu-west-1a
  count=1
  user_data_file=default.userdata.yml
  name_tag=aruba
  instance_type="t2.micro"
  security_group_name=

  while getopts :k:i:s:c:u:n:g: opt; do
    case $opt in
      k)
        key_name=$OPTARG
        ;;
      i)
        image_id=$OPTARG
        ;;
      s)
        subnet_id=$OPTARG
        ;;
      c)
        count=$OPTARG
        ;;
      u)
        user_data_file=$OPTARG
        ;;
      n)
        name_tag=$OPTARG
        ;;
      g)
        security_group_name=$OPTARG
        ;;
    esac
  done

  if [[ -z "${key_name}" || -z "${image_id}" ]]; then
    echo
    echo "Usage: ${0} -k key_name -i image_id [ -s subnet_id  -c count -u user_data_file -n name_tag -g security_group_name]"
    echo
    echo 'recommended imageid: ami-bff32ccc'
    exit 1
  fi
}

parse_options $@

if [[ -n "${security_group_name}" && "${security_group_name}" != "default" ]]; then
  echo "Getting id for security group: ${security_group_name}"
  sec_group_id=$(aws ec2 describe-security-groups | grep "${security_group_name}" | cut -f3)
else
  sec_group_id="sg-f69d5f92"
fi

echo "Security for ${security_group_name} is ${sec_group_id}"
echo "Running instances..."
awsresult=$(aws ec2 run-instances \
  --instance-type t2.micro \
  --associate-public-ip-address \
  --key-name ${key_name} \
  --image-id ${image_id} \
  --subnet-id ${subnet_id} \
  --security-group-ids ${sec_group_id} \
  --count ${count} \
  --user-data "$(<${user_data_file})")

instance_ids=$(grep INSTANCES <<< "${awsresult}" | cut -f8)
if [[ -n "${instance_ids}" ]]; then
  echo "Instance ids: ${instance_ids}"
  echo "Tagging instances with name: ${name_tag}"
  aws ec2 create-tags --resources ${instance_ids} --tags Key=Name,Value=${name_tag}
  echo
  echo "Public IPs:"
  aws ec2 describe-instances --instance-ids ${instance_ids}| grep ASSOCIATION | uniq | cut -f4
else
  echo "No instance ids returned!"
fi
