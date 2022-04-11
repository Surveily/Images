#!/bin/bash

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/repository.sh | sudo sh -s -- <password>

set -e

HOURS=1000
PASSWORD=$1

declare -a frequent=(
    "surveily.init"
    "surveily.backend.graph"
    "surveily.cognition.service"
    "surveily.data.api"
    "surveily.data.web"
)

for t in ${frequent[@]}; do
  echo $t
  docker run -it --rm anoxis/registry-cli -r https://registry.surveily.com -l surveily:$PASSWORD -i $t --delete-by-hours $HOURS --keep-tags-like latest
done
