#!/bin/bash

PHP_VERSION="7.2"
# run as root (ie sudo )

if [ -z "$VHOST_DATA_DIR" ]; then
    VHOST_DATA_DIR="/opt/vhost/"
fi

# Add vhost group if not present
grep -q vhost /etc/group
if [ "$?" -ne 0 ]; then
    groupadd vhost
fi

cp 50-vhost /etc/sudoers.d/
cp vhost.sh /usr/local/bin
cp -r nginx-templates/*.template $VHOST_DATA_DIR/nginx-templates

# Get the path of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

setfacl -m g:vhost:rwx /usr/share/nginx/html/
setfacl -m d:g:vhost:rwx /usr/share/nginx/html/
setfacl -m g:vhost:rwx /etc/nginx/sites-available/
setfacl -m d:g:vhost:rwx /etc/nginx/sites-available/
 
# Give write access to the nginx sites enabled folder
setfacl -m g:vhost:rwx /etc/nginx/sites-enabled/
setfacl -m d:g:vhost:rwx /etc/nginx/sites-enabled/

if [ ! -d "$VHOST_DATA_DIR" ]; then
    mkdir "$VHOST_DATA_DIR"
    mkdir $VHOST_DATA_DIR/nginx-templates &2> /dev/null
fi
for f in $DIR/nginx-templates/* ; do
    cat $f | sed -e "s/php7.0/php$PHP_VERSION/g" > $VHOST_DATA_DIR/nginx-templates/$(basename $f)
done

if [ ! -f $VHOST_DATA_DIR/data.db ]; then
    sqlite3 $VHOST_DATA_DIR/data.db  <<EOD
		CREATE TABLE users ( 
			id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, 
			name TEXT NOT NULL UNIQUE ON CONFLICT ROLLBACK, 
			key TEXT NOT NULL,
			value TEXT);
EOD

fi

chgrp vhost "$VHOST_DATA_DIR"
chgrp vhost "$VHOST_DATA_DIR/data.db"
chmod 770 "$VHOST_DATA_DIR"
chmod 664 "$VHOST_DATA_DIR/data.db"
