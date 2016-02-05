#!/bin/bash


function parse_options() {
  num_instances=1
  image_id=
  key_name=
  
  while getopts :n:i:k: opt; do
    case $opt in
      n) 
        num_instances=$OPTARG
        ;;
      i)
        image_id=$OPTARG
        ;;
      k)
        key_name=$OPTARG
        ;;
     esac
  done

  if [[ -z "${key_name}" ]]; then
    echo 
    echo "Usage: ${0} -k aws_keyname -i ami_id [ -n num_instances ]"
    echo
    exit 1 
  fi
}

parse_options $@

echo "instances: ${num_instances}"
echo "image id: ${image_id}"
echo "keyname: ${key_name}"
