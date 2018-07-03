#!/bin/bash
# nullglob to allow for testing if file exists
shopt -s nullglob # enable


# Get the path of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -z "$VHOST_DATA_DIR" ]; then
    VHOST_DATA_DIR="/opt/vhost/"
fi

if [ "$1 $2" = "templates list" ]; then
    echo -e "Available Templates\n"
    files=( $VHOST_DATA_DIR/nginx-templates/*.template )
    for f in "${files[@]}"
    do
        # Remove the pathname
        f=${f##*/}
        # Remove the .template extension
        f=${f%%.*}
        echo  "$f"

    done
elif [ "$1" = "create" ]; then
    if [ -z "$2" ]; then
        echo "please supply a template name"
        exit 1
    fi
    if [ -z "$3" ]; then
        echo "please supply a domain name"
        exit 1
    fi
    if [ ! -f  "$VHOST_DATA_DIR/nginx-templates/$2.template" ]; then
        echo "No such template $2"
        exit 1
    fi
    if [ -f  "/etc/nginx/sites-available/$3.conf" ]; then
        echo "vhost for $3 already exists"
        exit 1
    fi
    cat "$VHOST_DATA_DIR/nginx-templates/$2.template" | sed -e "s/domain\.com/$3/g" > "/etc/nginx/sites-available/$3.conf"
    if [ ! -d "/usr/share/nginx/html/$3/" ]; then
        mkdir  "/usr/share/nginx/html/$3/"
    fi
	ln -s "/usr/share/nginx/html/$3/"  "$HOME/$3"
	ln -s "/etc/nginx/sites-available/$3.conf"  "/etc/nginx/sites-enabled/$3.conf"
    echo "vhost $domain created and enabled"
    echo "remember to reload nginx with \"sudo service nginx reload\""
elif [ "$1" = "destroy" ]; then
    if [ -z "$2" ]; then
        echo "No domain supplied"
        exit 1
    fi
    if [ ! -f "/etc/nginx/sites-available/$2.conf" ]; then
        echo "domain vhost $2 does not exist - no action taken"
        exit 1
    fi
    rm "/etc/nginx/sites-enabled/$2.conf" 2>/dev/null
    rm "/etc/nginx/sites-enabled/ssl/$2.conf" 2>/dev/null
    rm "/etc/nginx/sites-available/$2.conf"
    rm -fr "/usr/share/nginx/html/$2/"
    rm "$HOME/$2"

    echo "vhost $domain destroyed"
    echo "remember to reload nginx with \"sudo service nginx reload\""
elif [ "$1" = "disable" ]; then
    if [ -z "$2" ]; then
        echo "No domain supplied"
        exit 1
    fi
    if [ ! -L "/etc/nginx/sites-enabled/$2.conf" ]; then
        echo "vhost symlink for domain $2 does not exist - no action taken"
        exit 1
    fi
    rm "/etc/nginx/sites-enabled/$2.conf"

    echo "symlink for vhost $domain deleted"
    echo "remember to reload nginx with \"sudo service nginx reload\""
elif [ "$1" = "enable" ]; then
    if [ -z "$2" ]; then
        echo "No domain supplied"
        exit 1
    fi
    if [ -L "/etc/nginx/sites-enabled/$2.conf" ]; then
        echo "vhost symlink for domain $2 already exists - no action taken"
        exit 1
    fi
    if [ ! -f "/etc/nginx/sites-available/$2.conf" ]; then
        echo "vhost entry for domain $2 missing - no action taken"
        echo "suggest recreating the vhost to fix"
        exit 1
    fi
    ln -s "/etc/nginx/sites-available/$2.conf" "/etc/nginx/sites-enabled/$2.conf"

    echo "symlink for vhost $domain created"
    echo "remember to reload nginx with \"sudo service nginx reload\""
elif [ "$1" = "set" ]; then
    if [ -z "$2" ]; then
        echo "No key supplied"
        exit 1
    fi
    if [ -z "$3" ]; then
        echo "No value supplied"
        exit 1
    fi
	KEY=$2
	VALUE=$3
	currval=$( sqlite3 $VHOST_DATA_DIR/data.db \
		"select value from users where name='$USER' and key='$2'" )
	if [ -z "$currval" ]; then
		sqlite3 $VHOST_DATA_DIR/data.db \
			"insert into users (name, key, value) values ('$USER', '$KEY', '$VALUE')"
	else
		sqlite3 $VHOST_DATA_DIR/data.db \
			"update users set value = '$VALUE' where name ='$USER' and key = '$KEY' "

	fi
elif [ "$1" = "show" ]; then
    if [ -z "$2" ]; then
		sqlite3 $VHOST_DATA_DIR/data.db \
		"select key, value from users where name='$USER'"
        exit 1
    fi
	KEY=$2
	sqlite3 $VHOST_DATA_DIR/data.db \
		"select value from users where name='$USER' and key = '$KEY' "
fi
