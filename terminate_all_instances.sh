#!/bin/bash
base_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


function yes_no() {
  while true; do
    read -p "Really terminate ALL running instances? [y/n]: " yn
    case $yn in
      [Yy]* ) break;;
      [Nn]* ) echo "Goodbye!"; exit 0;;
          * ) echo "Goodbye!"; exit 0;;
    esac
  done
}

# find only running instances
ids=$(aws ec2 describe-instances --output text --filters Name=instance-state-name,Values=running | grep INSTANCES | cut -f8 | tr '\n' ' ')
if [[ -z "${ids}" ]]; then
  echo "No running instances to terminate"
else
  yes_no
  aws ec2 terminate-instances --instance-ids ${ids}
fi

#echo "Deleting volumes"
#${base_dir}/delete_available_volumes.sh
