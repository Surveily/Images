#! /usr/bin/env bash

# Example build agent run script

docker pull surveily/developer.dotnet:3.1-build
docker rm $1 -f
docker volume rm $1-varunit
docker run --privileged --name $1 -d --restart always --cpus=.66 -v /Users/service/.ssh:/root/.ssh -v $1-varunit:/etc/varunit -v /var/run/docker.sock:/var/run/docker.sock --env-file agent.env -e AGENT=$1 surveily/developer.dotnet:3.1-build