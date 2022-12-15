#!/bin/bash

VAULT_VERSION="v1.8.12"
CN_NAME="appsmith-$VAULT_VERSION"

mkdir -p $HOME/appsmith-stacks

docker run -d --name $CN_NAME --restart unless-stopped \
-p 127.0.0.1:8090:80 \
-v $HOME/appsmith-stacks:/appsmith-stacks \
--net pg-net --ip 172.20.0.4 \
index.docker.io/appsmith/appsmith-ce:$VAULT_VERSION
