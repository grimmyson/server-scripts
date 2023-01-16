#!/bin/bash

checkDB_NAME() {
  if [ -z "$DB_NAME" ]; then
    echo "Please set database name variable, use:"
    echo "export DB_NAME="
    exit 1
  fi
  echo "Database name: $DB_NAME"
}

checkDUMP_FILE() {
  if [ -z "$DUMP_FILE" ]; then
    echo "Please set dump file name, use:"
    echo "export DUMP_FILE="
    exit 1
  fi
  echo "Dump file name: $DUMP_FILE"
}

COMMAND=$1
PG_VERSION="15.1"
CN_NAME="postgres-$PG_VERSION"

if [[ $COMMAND == "run-container" ]]; then
  PG_FOLDER="$HOME/postgres-db"
  PG_PASSWORD="$PG_FOLDER/pg_password"

  if [ ! -f $PG_PASSWORD ]; then
    echo "Create a ~/postgres-db/pg_password file with the password"
    exit 1
  fi

  if [[ $(docker network ls | grep pg-net | wc -l) -eq 0 ]]; then
    docker network create --subnet 172.20.0.0/16 pg-net
  fi

  PGPASS="/run/secrets/pg_password"
  PGDATA="/var/lib/postgresql/data/pgdata"

  docker run -d --name $CN_NAME --restart unless-stopped \
  -p 127.0.0.1:5432:5432 \
  -e PGDATA=$PGDATA -e POSTGRES_PASSWORD_FILE=$PGPASS \
  -v $PG_FOLDER:$PGDATA -v $PG_PASSWORD:$PGPASS \
  --net pg-net --ip 172.20.0.2 \
  postgres:$PG_VERSION

  echo "" > $PG_PASSWORD
elif [[ "$COMMAND" == "dump" ]]; then
  checkDB_NAME
  docker exec $CN_NAME pg_dump -U postgres --format=t $DB_NAME | gzip -9 > $DB_NAME-$(date +%Y-%m-%d_%H-%M-%S).gz
elif [[ "$COMMAND" == "restore" ]]; then
  checkDB_NAME
  checkDUMP_FILE

  docker exec $CN_NAME psql -U postgres -c "drop database if exists $DB_NAME"
  docker exec $CN_NAME psql -U postgres -c "create database $DB_NAME"
  gunzip -k < $DUMP_FILE | docker exec -i $CN_NAME pg_restore -U postgres -d $DB_NAME
elif [[ "$COMMAND" == "info" ]]; then
  echo "Container: $CN_NAME"
  echo "Database:  $DB_NAME"
  echo "Dump file: $DUMP_FILE"
else
  echo "Syntax:"
  echo ""
  echo "./pg-docker.sh run-container|dump|restore|info"
  echo ""
  exit 1
fi
