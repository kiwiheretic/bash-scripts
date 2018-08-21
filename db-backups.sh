#!/bin/bash
dbs=$(mysql -e 'show databases' | sed -e 's/|[:blank:]+//')
for db in $dbs; do
    grep -q -e $db <<DONE
Database
information_schema
mysql
performance_schema
phpmyadmin
sys
DONE
    # if not one of the databases listed in the above grep clause
    if [ $? -ne 0 ] ; then
        echo "Backing up $db"
        mysqldump $db | gzip > $HOME/backups/$db-db-$(date | sed -e 's/[ :]\+/-/g').sql.gz
    fi
done
