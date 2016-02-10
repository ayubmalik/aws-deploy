#!/bin/bash

function parse_options() {
  key_name=
  image_id=
  subnet_id=subnet-7b5c270c #eu-west-1a
  count=1
  user_data_file=default.userdata.yml
  name_tag=aruba
  instance_type="t2.micro"

  while getopts :k:i:s:c:u:n: opt; do
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
    esac
  done

  if [[ -z "${key_name}" || -z "${image_id}" ]]; then
    echo
    echo "Usage: ${0} -k key_name -i image_id [ -s subnet_id  -c count -u user_data_file -n name_tag]"
    echo
    echo 'recommended imageid: ami-bff32ccc'
    exit 1
  fi
}

parse_options $@

awsresult=$(aws ec2 run-instances \
  --instance-type t2.micro \
  --associate-public-ip-address \
  --key-name ${key_name} \
  --image-id ${image_id} \
  --subnet-id ${subnet_id} \
  --count ${count} \
  --user-data "$(<${user_data_file})")

echo "${awsresult}"
instance_ids=$(grep INSTANCES <<< "${awsresult}" | cut -f8)

if [[ ! -z ${instance_ids} ]]; then
  echo
  echo "Tagging instances with name: ${name_tag}"
  aws ec2 create-tags --resources ${instance_ids} --tags Key=Name,Value=${name_tag}
  echo
  echo "Public IPs:"
  aws ec2 describe-instances --instance-ids ${instance_ids}| grep ASSOCIATION | uniq | cut -f4
fi
