#!/bin/bash

. ./.env

PRJID=
ENV=staging
DUMP_FILENAME=${PRJ}_${ENV}-`date +%Y%m%d`
RELATIONSHIP=database-slave

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
echo "   Determining database connection to use ..."
magento-cloud environment:relationships --project=$PJID --environment=$ENV --property=database-slave.0.host > /dev/null 2>&1
[[ $? > 0 ]] && RELATIONSHIP=database

echo "   Dumping Magento Cloud database structure ..."
magento-cloud db:dump --project=$PRJID --environment=$ENV --schema-only --relationship=$RELATIONSHIP --stdout | sed 's/\/\*[^*]*DEFINER=[^*]*\*\///g' > /tmp/$DUMP_FILENAME-struct.sql

echo "⏳ Dumping Magento Cloud database data ..."
magento-cloud db:dump --project=$PRJID --environment=$ENV --relationship=$RELATIONSHIP --stdout | sed 's/\/\*[^*]*DEFINER=[^*]*\*\///g' > /tmp/$DUMP_FILENAME-data.sql

echo "   Copying dump files to container ..."
docker compose cp /tmp/$DUMP_FILENAME-struct.sql database:/tmp/
docker compose cp /tmp/$DUMP_FILENAME-data.sql database:/tmp/
docker compose exec database /usr/local/bin/generate-my-cnf.sh

echo "   Restoring database structure ..."
docker compose exec database /bin/sh -c "mysql ${SITE_ID}_db < /tmp/$DUMP_FILENAME-struct.sql"

echo "🔥 Restoring database data ..."
docker compose exec database /bin/sh -c "mysql ${SITE_ID}_db < /tmp/$DUMP_FILENAME-data.sql"

echo "   Removing dump files from container ..."
docker compose exec database /bin/sh -c "rm /tmp/$DUMP_FILENAME-*.sql"

echo "   Removing dump files from host ..."
rm /tmp/$DUMP_FILENAME-*.sql

# Stop the database if we started it
[[ $launchedDatabaseContainer == "1" ]] && docker compose down ${SITE_ID}_database

echo "Done"
