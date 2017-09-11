#!/bin/ash

# Check to see if variables have data in them.
if [ ! $MYSQL_SERVER ] || [ ! $MYSQL_USER ]; then
  echo "[$(date +"%Y-%m-%d %H:%M:%S:%3N %Z")] CRIT: MySQL variables not populated: failing."
  exit
fi

# Check to see if the drupal db has enough tables. if not, load starter.sql

for i in {1..5};
do
  if mysql -h $MYSQL_SERVER -e ';' 2> /dev/null; then
    echo "[$(date +"%Y-%m-%d %H:%M:%S:%3N %Z")] NOTICE: MySQL connection successful"
  
    # Get table count in database assigned by MYSQL_DATABASE.
    table_count=`mysql -B --disable-column-names --host $MYSQL_SERVER --execute="select count(*) from information_schema.tables where table_type = 'BASE TABLE' and table_schema = '$MYSQL_DATABASE'" -s`
  
    if [ "$?" = "0" ]; then
      echo "i[$(date +"%Y-%m-%d %H:%M:%S:%3N %Z")] NOTICE: Successfully got table count of $table_count"
      if [ $table_count -lt 2 ]; then
        echo "[$(date +"%Y-%m-%d %H:%M:%S:%3N %Z")] NOTICE: Table count too low, checking for starter.sql"
        if [ -e /var/www/site/starter.sql ]; then
          echo "[$(date +"%Y-%m-%d %H:%M:%S:%3N %Z")] NOTICE: starter.sql exists. Starting import."
          mysql --host $MYSQL_SERVER $MYSQL_DATABASE < /var/www/site/starter.sql
        else
          echo "[$(date +"%Y-%m-%d %H:%M:%S:%3N %Z")] WARN: starter.sql doesn't exist.  Manually import database to continue."
        fi
      else
        echo "[$(date +"%Y-%m-%d %H:%M:%S:%3N %Z")] NOTICE: Database is already populated. Exiting script."
        exit
      fi
  
    else
      echo "[$(date +"%Y-%m-%d %H:%M:%S:%3N %Z")] CRIT: We were not able to get table count from MySQL server"
    fi
  else
    echo "[$(date +"%Y-%m-%d %H:%M:%S:%3N %Z")] CRIT: We were not able to connect to MySQL"
    echo "Trying again after 10 seconds"
    sleep 10
  fi
done
