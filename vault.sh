#!/bin/bash

VAULT_VERSION="1.15.2"
CN_NAME="vault-$VAULT_VERSION"

mkdir -p $HOME/vault/{file,config}

cat << EOF > $HOME/vault/config/vault.json
{
  "backend": {
    "file": {
      "path": "/vault/file"
    }
  },
  "listener": {
    "tcp": {
      "address": "0.0.0.0:8200",
      "tls_disable": true
    }
  },
  "default_lease_ttl": "365d",
  "max_lease_ttl": "365d",
  "ui": false
}
EOF

docker run -d --name $CN_NAME --restart unless-stopped \
-p 127.0.0.1:8200:8200 \
-v $HOME/vault/file:/vault/file:rw \
-v $HOME/vault/config:/vault/config \
-e VAULT_ADDR='http://127.0.0.1:8200' \
-e VAULT_API_ADDR='http://127.0.0.1:8200' \
--cap-add=IPC_LOCK \
--net pg-net --ip 172.20.0.3 \
hashicorp/vault:$VAULT_VERSION server

echo ""
echo "Use this command to initialize the vault:"
echo "/ # vault operator init -key-shares=2 -key-threshold=2"
echo "Keep the generated keys and token."
echo ""
echo "Use these commands for vault configuration:"
echo "/ # vault operator unseal"
echo '/ # export VAULT_TOKEN="{paste_token}"'
echo "/ # vault secrets enable kv"
echo ""
echo "After adding parameters and your application runs use:"
echo "/ # vault operator seal"
echo ""

docker exec -it $CN_NAME /bin/sh
