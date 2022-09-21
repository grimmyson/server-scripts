#!/bin/bash

checkCN_NAME() {
  if [ -z "$CN_NAME" ]; then
    echo "Please set container name variable, use:"
    echo "export CN_NAME="
    exit 1
  fi
  echo "Container name: $CN_NAME"
}

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

if [[ $COMMAND == "run-pg-container" ]]; then
  checkCN_NAME

  PG_PASS=$(cat pgpass.txt 2> /dev/null)
  if [ -z "$PG_PASS" ]; then
    echo "Create pgpass.txt file with genereted password"
    exit 1
  fi

  PGDATA="/var/lib/postgresql/data/pgdata"
  PG_FOLDER="$HOME/postgres-14.5-db"
  
  mkdir -p $PG_FOLDER

  docker run -d --name $CN_NAME --restart unless-stopped \
  -p 5432:5432 \
  -e PGDATA=$PGDATA -e POSTGRES_PASSWORD=$PG_PASS \
  -v $PG_FOLDER:$PGDATA postgres:14.5
elif [[ "$COMMAND" == "dump" ]]; then
  checkCN_NAME
  checkDB_NAME

  docker exec $CN_NAME pg_dump -U postgres --format=t $DB_NAME | gzip -9 > $DB_NAME-$(date +%Y-%m-%d_%H-%M-%S).gz
elif [[ "$COMMAND" == "restore" ]]; then
  checkCN_NAME
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
  echo "./pg-docker-script.sh run-pg-container|dump|restore|info"
  echo ""
  exit 1
fi
