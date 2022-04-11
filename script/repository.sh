#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/repository.sh | sudo sh -s -- <password>

set -e

HOURS=1000
PASSWORD=$1

set -- "surveily.init" "surveily.backend.graph" "surveily.cognition.service" "surveily.data.api" "surveily.data.web"
while [ -n "$1" ]; do
  echo $1
  docker run -it --rm anoxis/registry-cli -r https://registry.surveily.com -l surveily:$PASSWORD -i $1 --delete-by-hours $HOURS --keep-tags-like latest
  shift
done
