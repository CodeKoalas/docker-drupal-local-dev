#!/bin/bash

# Check to see if variables have data in them.
if [ ! $MYSQL_SERVER ] || [ ! $MYSQL_USER ]; then
  echo "[$(date +"%Y-%m-%d %H:%M:%S:%3N %Z")] CRIT: MySQL variables not populated: failing."
  exit
fi

# Check to see if the drupal db has enough tables. if not, load starter.sql

if [ 'mysql -h $MYSQL_SERVER -e ";"' ]; then
  echo "[$(date +"%Y-%m-%d %H:%M:%S:%3N %Z")] NOTICE: MySQL connection successful"
else
  exit
fi

mysqldump --host $MYSQL_SERVER --ignore-table=$MYSQL_DATABASE.watchdog $MYSQL_DATABASE > /var/www/site/starter.sql
mysqldump --host $MYSQL_SERVER --no-data $MYSQL_DATABASE watchdog >> /var/www/site/starter.sql
