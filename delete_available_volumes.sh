#!/bin/bash
base_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# find only available volumes
ids=$(aws ec2 describe-volumes --output text --filters Name=status,Values=available | grep VOLUMES | cut -f8 | tr '\n' ' ')
for volume_id in ${ids}; do
  echo "Deleting volume: ${volume_id}"
  aws ec2 delete-volume --volume-id ${volume_id}
done
