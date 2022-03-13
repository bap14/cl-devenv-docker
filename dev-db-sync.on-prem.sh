#!/bin/bash

. ./.env

SSH_HOST=
SSH_USER=www-data
ENV=staging
STRIP_FLAG='@log @trade @search'
DUMP_FILENAME=${PRJ}_${ENV}-`date +%Y%m%d`

launchedDatabaseContainer=0
docker ps | grep ${SITE_ID}_database
if [[ $? > 0 ]]; then
  echo "Docker database is not running, attempting to start database container ..."
  docker compose up -d database
  docker ps | grep ${SITE_ID}_database
  if [[ $? > 0 ]]; then
    echo "Docker database failed to start up"
    exit 1
  fi
  launchedDatabaseContainer=1
fi

echo "Starting database sync from ${ENV}..."

echo "⏳ Dumping database structure ..."
ssh -o StrictHostKeyChecking=no ${SSH_USER}@${SSH_HOST} <<END
if [[ ! -f ~/backup/$DUMP_FILENAME.sql.gz ]]; then
    /usr/local/bin/mr --root-dir=/var/www/data/current db:dump -c gz --strip="$STRIP_FLAG" -- /tmp/$DUMP_FILENAME.sql.gz
fi
END

echo "   Downloading database dump from remote server ..."
scp -o StrictHostKeyChecking=no ${SSH_USER}@${SSH_HOST}:/tmp/$DUMP_FILENAME.sql.gz .

echo "   Copying dump files to container ..."
docker compose cp /tmp/$DUMP_FILENAME.sql.gz database:/tmp/
docker compose exec database /usr/local/bin/generate-my-cnf.sh

echo "🔥 Restoring database data ..."
docker compose exec database /bin/sh -c "gunzip /tmp/$DUMP_FILENAME.sql.gz"
docker compose exec database /bin/sh -c "mysql ${SITE_ID}_db < /tmp/$DUMP_FILENAME.sql"

echo "   Removing dump files from container ..."
docker compose exec database /bin/sh -c "rm /tmp/$DUMP_FILENAME.sql"

echo "   Removing dump files from host ..."
rm /tmp/$DUMP_FILENAME.sql

# Stop the database if we started it
[[ $launchedDatabaseContainer == "1" ]] && docker compose down ${SITE_ID}_database

echo "Done"
