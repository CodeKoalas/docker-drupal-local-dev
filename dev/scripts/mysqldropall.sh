#!/bin/bash

TABLES=$(mysql -h $MYSQL_SERVER $MYSQL_DATABASE -e 'show tables' | awk '{ print $1}' | grep -v '^Tables' )

for t in $TABLES
do
	echo "Deleting $t table from $MYSQL_DATABASE database..."
	mysql -h $MYSQL_SERVER $MYSQL_DATABASE -e "drop table $t"
done
