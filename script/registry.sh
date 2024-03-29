#!/bin/bash

# Run: wget https://raw.githubusercontent.com/Surveily/Images/master/script/registry.sh && chmod +x registry.sh && ./registry.sh <password>

set -e

HOURS=336
PASSWORD=$1

declare -a frequent=(
    "build"
    "surveily.init"
    "surveily.backend.graph"
    "surveily.cognition.service"
    "surveily.data.api"
    "surveily.data.web"
)

for t in ${frequent[@]}; do
  echo $t
  docker run --rm anoxis/registry-cli -r https://registry.surveily.com -l surveily:$PASSWORD -i $t --delete-by-hours $HOURS --keep-tags-like latest
done
