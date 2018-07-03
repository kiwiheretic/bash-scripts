#!/bin/bash

# run as root (ie sudo )

if [ -z "$VHOST_DATA_DIR" ]; then
    VHOST_DATA_DIR="/opt/vhost/"
fi

# Add vhost group if not present
grep -q vhost /etc/group
if [ "$?" -ne 0 ]; then
    echo groupadd vhost
fi

cp 50-vhost /etc/sudoers.d/

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
    cp $DIR/nginx-templates $VHOST_DATA_DIR/nginx-templates    
fi

if [ ! -f $VHOST_DATA_DIR/data.db ]; then
    sqlite3 $VHOST_DATA_DIR/data.db  <<EOD
		CREATE TABLE users ( 
			id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, 
			name TEXT NOT NULL UNIQUE ON CONFLICT ROLLBACK, 
			email TEXT NOT NULL);
EOD

fi
