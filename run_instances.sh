#!/bin/bash

function parse_options() {
  key_name=
  image_id=
  subnet_id=subnet-7b5c270c #eu-west-1a
  count=1
  user_data_file=default.userdata.yml

  while getopts :k:i:s:n:u: opt; do
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
      n)
        count=$OPTARG
        ;;
      u)
        user_data_file=$OPTARG
        ;;
    esac
  done

  if [[ -z "${key_name}" || -z "${image_id}" ]]; then
    echo
    echo "Usage: ${0} -k key_name -i image_id [ -s subnet_id [ -n count -u user_data_file ]"
    echo
    exit 1
  fi
}

parse_options $@

aws ec2 run-instances \
  --instance-type t2.micro \
  --key-name ${key_name} \
  --image-id ${image_id} \
  --subnet-id ${subnet_id} \
  --count ${count} \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"DeleteOnTermination":true}}]' \
  --user-data "$(<${user_data_file})"
