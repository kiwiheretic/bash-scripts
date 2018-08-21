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
    domains="${@:3}"
    if [ ! -f  "$VHOST_DATA_DIR/nginx-templates/$2.template" ]; then
        echo "No such template $2"
        exit 1
    fi
    cat "$VHOST_DATA_DIR/nginx-templates/$2.template" | sed -e "s/domains\.com/$domains/g" | sed -e "s/domain\.com/$3/g" > "/etc/nginx/sites-available/$3.conf"
    if [ ! -d "/usr/share/nginx/html/$3/" ]; then
        mkdir  "/usr/share/nginx/html/$3/"
    fi
	ln -s "/usr/share/nginx/html/$3/"  "$HOME/$3"
	ln -s "/etc/nginx/sites-available/$3.conf"  "/etc/nginx/sites-enabled/$3.conf" 
    echo "vhost $domains created and enabled"
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
elif [ "$1" = "mv" ]; then
    srcdomain=$2
    targetdomain=$3
    if [ -z "$srcdomain" ]; then
        echo "please supply a source domain name"
        exit 1
    fi
    if [ -z "$targetdomain" ]; then
        echo "please supply a target domain name"
        exit 1
    fi
    ## Find all symlinks that $srcdomain points to recursively until we find the
    ## actual folder, these are added to array arr
    arr=()
    tmp=$( readlink "$HOME/$srcdomain" )
    webfolder=${tmp%/}  # strip trailing slash
    arr+=($webfolder) # push web folder link to end of array
    while [ -n "$(readlink $webfolder)" ] ; do
        tmp=$( readlink "$webfolder" ) # traverse the symlink
        webfolder=${tmp%/} # strip trailing slash
        arr+=($webfolder) #  push web folder link to end of array
    done
    echo "----"
    # we are using a reverse index traversing the array backwards
    # so that we can adjust every symlink to match the new domain
    idx=$((${#arr[@]}-1)) ## Subtract 1 from idx
    lastidx=$idx  # remember idx to end of array
    t="${arr[$idx]}" # get tail element from array
    tgt=$(echo "$t" | sed -e "s:$srcdomain:$targetdomain:") # adjust symlink path to new domain
    while [ $idx -ge 0 ] ; do
        if [ $idx -eq $lastidx ] ; then  # If last symlink
            echo "mv \"$t\" \"$tgt\""  # just rename it
            mv \"$t\" \"$tgt\"  # just rename it
        else # otherwise remove it and recreate it
            echo "rm \"$t\""
            rm \"$t\"
            last_target=$( echo ${arr[$(($idx+1))]} | sed -e "s|$srcdomain|$targetdomain|" )
            echo "ln -s \"$tgt\" \"$last_target\" "
            ln -s \"$tgt\" \"$last_target\" 
        fi
        # move to previous element in array
        idx=$(($idx-1))  # decrement index
        t="${arr[$idx]}" # get symlink element at that index
        tgt=$(echo "$t" | sed -e "s:$srcdomain:$targetdomain:")  # replace domain for that symlink
    done
    if [ ! -L "$HOME/$srcdomain" ]; then
        echo "vhost symlink for domain $srcdomain does not exist in home folder"
    else
        echo "renaming home symlink $1 to $srcdomain"
        echo "rm $HOME/$srcdomain"
        rm "$HOME/$srcdomain"
        target=$( echo ${arr[0]} | sed -e "s|$srcdomain|$targetdomain|" )
        echo "ln -s $target $HOME/$srcdomain"
        ln -s "$target" "$HOME/$srcdomain"
    fi
    echo "++++"
	# Find all current domains listed in the config file
    # and add the new $targetdomain and remove $srcdomain
    x=$( cat "/etc/nginx/sites-enabled/$srcdomain.conf" | grep -e "server_name" | head -n1 | sed -e 's/server_name\|;//g' )
	newlist=""
	for e in ${x}; do
		if [ $e != $srcdomain ]; then
			newlist="$newlist $e"
		fi
	done
    # add $targetdomain into list if not already present
	if [[ $newlist != *"$targetdomain"* ]]; then
	  newlist="$targetdomain $newlist"
	fi
	echo $newlist
    cat /etc/nginx/sites-available/$srcdomain.conf | sed -e "/server_name/c\    server_name  $newlist ;" > /tmp/nginx.config.1
    cat /tmp/nginx.config.1 | sed -e "/error_log/s|error_log \(.*\)|error_log /var/log/nginx/$targetdomain.error.log;|" > /tmp/nginx.config.2
    cat /tmp/nginx.config.2 | sed -e "/access_log/s|access_log \(.*\)|access_log /var/log/nginx/$targetdomain.error.log combined;|" > /tmp/nginx.config.3
    cp /tmp/nginx.config.3 /etc/nginx/sites-available/$targetdomain.conf
    rm /tmp/nginx.config.*
    rm /etc/nginx/sites-available/$srcdomain.conf
    #cat /tmp/nginx.config.3 | sed -e "/ssl_certificate /s|ssl_certificate (.*)|ssl_certificate /etc/letsencrypt/live/$targetdomain/fullchain.pem|" > /tmp/nginx.config.4
    if [ -L /etc/nginx/sites-enabled/$srcdomain.conf ] ; then
        echo "rm \"/etc/nginx/sites-enabled/$srcdomain.conf\" "
        rm "/etc/nginx/sites-enabled/$srcdomain.conf"
        echo "ln -s \"/etc/nginx/sites-available/$targetdomain.conf\" \"/etc/nginx/sites-enabled/$targetdomain.conf\""
        ln -s "/etc/nginx/sites-available/$targetdomain.conf" "/etc/nginx/sites-enabled/$targetdomain.conf"
    fi
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
elif [ "$1" = "getcert" ]; then
    email=$(sqlite3 $VHOST_DATA_DIR/data.db \
            "select value from users where name='$USER' and key = 'email' " )
    if [ -z "$email" ]; then
        echo "No email set - set with \" vhost.sh set email <email>\" "
        exit 1
    fi
    # we allow multiple domains to be added to certificate
    domains=""
    for i in "${@:2}"
    do
        domains="$domains -d $i"
    done
    sudo certbot certonly --webroot -w /var/www/letsencrypt $domains --agree-tos -m "$email"
elif [ "$1" = "revokecert" ]; then
    domain=$2
    sudo certbot revoke  --cert-path /etc/letsencrypt/live/$domain/fullchain.pem --delete-after-revoke
fi
