#!/bin/bash
# nullglob to allow for testing if file exists
shopt -s nullglob # enable

# bash function syntax expects argument brackets even though
# you're not allowed to actually put argument variables in there!!

func_nginx_conf () {

domain=$1

cat <<done

server {
    listen       80;
    listen       [::]:80; # ipv6only=on;
    server_name  $domain;

    gzip on;
    gzip_types      text/plain text/javascript application/x-javascript application/xml application/javascript text/css;

    rewrite_log on;
    root   /usr/share/nginx/html/$domain/;
    include acme_challenge.conf;
    index index.php index.html splats-test-page.html;
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    location ~* \\.(js|css|png|jpg|jpeg|gif|ico)(\\?ver=[0-9.]+)?$ {
        expires 7d;
    }

    location ~ \\.php$ {
        fastcgi_pass   unix:/var/run/php/php7.0-fpm.sock;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        include        fastcgi_params;
    }
}
done
} # end func_nginx_conf

func_test_page () {

cat  << done
<html>
<head>
<style>

body {
    text-align: center;
    margin: 0;
    padding: 0;
}
h1 {
    background: lightsteelblue;
    padding-top: 10px;
    padding-bottom:10px;
    font-family: "Arial Black", Gadget, sans-serif;
    color: white;
    position: fixed;
    width: 100%;
    margin-top: 0;
}

pre {
    background: lightblue;
    padding: 5px;
    display: block;
    margin-left: 7px;
}

#container {
    width: 550px;
    display: inline-block;
    text-align: left;
    padding-top: 60px;
    
}
#splat1 {
    float: left;
    padding: 5px;
    margin-top:5px;
}
</style>
</head>
<body>
<h1 style="text-align:center;">Splat's Test Page</h1>
<div id="container">
<img id="splat1" src="https://splatblogger.files.wordpress.com/2010/11/splat1.jpg?w=500" />
<h2>Virtual Hosts</h2>
<p>To create a virtual host:</p>
<pre>vhost.sh create &lt;domain&gt;</pre>
<p>To remove a virtual host:</p>
<pre>vhost.sh destroy &lt;domain&gt;</pre>
<p><strong>Warning:  This removes all files from your webserver permanently!</strong></p>
<p>If you just want to temporarily disable a virtual host:</p>
<pre>vhost.sh disable &lt;domain&gt;</pre>
<p>To reenable a previously disabled virtual host:</p>
<pre>vhost.sh enable &lt;domain&gt;</pre>
<h2>SSL</h2>
<p>To create a test SSL certificate:</p>
<pre>getcerttest &lt;domain&gt;</pre>
<p>To create a live SSL certificate:</p>
<pre>getcertlive &lt;domain&gt;</pre>
<p>To add SSL certificate to your site</p>
<pre>vhost.sh ssl enable &lt;domain&gt;</pre>
<p>To remove SSL certificate to your site (but doesn't destroy certificate)</p>
<pre>vhost.sh ssl disable &lt;domain&gt;</pre>
<p>Certificates are obtained from letsencrypt.org.
Only a small number (around 5) of live certificates can be obtained a week.  So best to test with test certificates until ready.  Test certificates will not
show as valid inside a browser.  To test the test certificate and indeed all certificates see below.</p>
<p>To test a domains certificates are installed:</p>
<pre>testcert &lt;domain&gt;</pre>
</div>
</body>
</html>
done
} # end func_test_page

func_redirect_conf () {

domain=$1
certpath=$2
cat <<done
# Automatically created by vhost.sh script
# This file will be overwritten every time this script runs!!
server {
    listen 80;
    # ipv6only causes major major restart issues
    listen [::]:80; #  ipv6only=on;
    server_name $domain;
    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
    return 302 https://$domain\$request_uri;
}

done
} # end func_redirect_conf

func_ssl () {

domain=$1
cat << done

server {
    listen       443 ssl;
    listen       [::]:443 ssl; # ipv6only=on;
    server_name  $domain;
    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;

    gzip on;
    gzip_types      text/plain text/javascript application/x-javascript application/xml application/javascript text/css;

    rewrite_log on;
    root   /usr/share/nginx/html/$domain/;
    include ssl.conf;
    index index.php index.html splats-test-page.html;
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    location ~* \\.(js|css|png|jpg|jpeg|gif|ico)(\\?ver=[0-9.]+)?$ {
        expires 7d;
    }

    location ~ \\.php$ {
        fastcgi_pass   unix:/var/run/php/php7.0-fpm.sock;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        include        fastcgi_params;
    }
}
done
} # end func_ssl

if test -z "$SUDO_USER"; then
    echo "Must be run with sudo"
    exit 1
fi

# check if user is in vhost group
if ! getent group vhost | grep -e "\b${SUDO_USER}\b" &> /dev/null ; then
    echo "user must be a member of vhost group to run this script"
    exit 1
fi 

# Get original user home directory
uhome=$(getent passwd splat | cut -d: -f6)

if [ ! -d $uhome ]; then
    echo "Home directory does not exist, script cannot run"
    exit 1
fi


if [ "$1" = "create" ]; then
    if [ -z "$2" ]; then
        echo "No domain supplied"
        exit 1
    fi
    domain=$2
    # check if domain already exists
    if [ -f "/etc/nginx/sites-available/$domain.conf" ]; then
        echo "domain vhost already exists - no action taken"
        exit 1
    fi
    mkdir /usr/share/nginx/html/$domain/ 2>/dev/null || true
    func_test_page > /usr/share/nginx/html/$domain/splats-test-page.html 
    ln -s /usr/share/nginx/html/$domain/ $uhome/$domain
    chown www-data:www-data $uhome/$domain
    chown --no-dereference ${SUDO_USER}.${SUDO_USER}  $uhome/$domain
    setfacl --recursive -m u:${SUDO_USER}:rwx $uhome/$domain
    setfacl --default -m u:${SUDO_USER}:rwx $uhome/$domain
    func_nginx_conf $domain > /etc/nginx/sites-available/$domain.conf 
    ln -s /etc/nginx/sites-available/$domain.conf  /etc/nginx/sites-enabled/$domain.conf
    service nginx reload
    echo "vhost $domain created and enabled"

elif [ "$1" = "recreate" ]; then
    if [ -z "$2" ]; then
        echo "No domain supplied"
        exit 1
    fi
    domain=$2
    # check if linked domain already exists
    if [ ! -L "$HOME/$domain" ]; then
        echo "link to domain folder doesn't exists - no action taken"
        exit 1
    fi
    mkdir /usr/share/nginx/html/$domain/ 2>/dev/null || true
    func_test_page > /usr/share/nginx/html/$domain/splats-test-page.html 
    if [ ! -L "$uhome/$domain" ] ; then
        ln -s /usr/share/nginx/html/$domain/ $uhome/$domain
    fi    
    chown www-data:www-data $uhome/$domain
    chown --no-dereference ${SUDO_USER}.${SUDO_USER}  $uhome/$domain
    setfacl --recursive -m u:${SUDO_USER}:rwx $uhome/$domain
    setfacl --default -m u:${SUDO_USER}:rwx $uhome/$domain
    func_nginx_conf $domain > /etc/nginx/sites-available/$domain.conf 
    if [ ! -L "/etc/nginx/sites-enabled/$domain.conf" ] ; then
        ln -s /etc/nginx/sites-available/$domain.conf  /etc/nginx/sites-enabled/$domain.conf
    fi    
    service nginx reload
    echo "vhost $domain recreated and enabled"
    echo "If you had ssl installed you will need to reenable it"
elif [ "$1" = "destroy" ]; then
    if [ -z "$2" ]; then
        echo "No domain supplied"
        exit 1
    fi
    if [ ! -f "/etc/nginx/sites-available/$2.conf" ]; then
        echo "domain vhost $2 does not exist - no action taken"
        exit 1
    fi
    rm /etc/nginx/sites-enabled/$2.conf 2>/dev/null
    rm /etc/nginx/sites-available/$2.conf
    rm -fr /usr/share/nginx/html/$2/
    rm ~/$2
    service nginx reload
    echo "vhost $2 destroyed"
elif [ "$1" = "disable" ]; then
    if [ -z "$2" ]; then
        echo "No domain supplied"
        exit 1
    fi
    if [ ! -L "/etc/nginx/sites-enabled/$2.conf" ]; then
        echo "domain vhost $2 does not exist - no action taken"
        exit 1
    fi
    echo "disabling domain $2"
    rm /etc/nginx/sites-enabled/$2.conf
    service nginx reload
    
elif [ "$1" = "enable" ]; then
    if [ -z "$2" ]; then
        echo "No domain supplied"
        exit 1
    fi
    if [ -L "/etc/nginx/sites-enabled/$2.conf" ]; then
        echo "domain vhost $2 already enabled  - no action taken"
        exit 1
    fi
    if [ ! -f "/etc/nginx/sites-available/$2.conf" ]; then
        echo "You need to create vhost first"
        exit 1
    fi
    echo "enabling domain $2"
    ln -s /etc/nginx/sites-available/$2.conf /etc/nginx/sites-enabled/$2.conf
    service nginx reload
    
elif [ "$1" = "list" ]; then
    for f in /etc/nginx/sites-available/*.conf
    do
        # the ## means remove the prefix pattern */ or everything preceding
        # the final slash from the variable f
        # the double ## is a greedy match
        f=${f##*/}

        # The % means remove the trailing pattern .conf from the
        # variable f and is non-greedy
        dom=${f%.conf}
        if [ -f "/etc/letsencrypt/live/$dom/cert.pem" ]; then
            if openssl x509 -text -noout -in "/etc/letsencrypt/live/$dom/cert.pem" | grep "Issuer" | grep "Fake" &> /dev/null ; then
                certname="(fake certificate)"
            else
                certname="(Live Certificate)"
            fi
        else
            certname=""
        fi

        # check if ssl enabled
        if [ -f "/etc/nginx/sites-available/ssl/$dom.ssl.conf" ]; then
            sslvhost="SSL Enabled"
        else
            sslvhost=""
        fi

        # check if user owns the file
        if [[ ( -d /usr/share/nginx/html/$dom )  && ( "$( stat --format=%U /usr/share/nginx/html/$dom)" = "$SUDO_USER" ) ]]; then 
            echo "$dom $certname $sslvhost"
        fi
    done
elif [ "$1" = "getcert" ]; then
    shift
    domain=$1
    if [ -z "$domain" ]; then
        echo "please supply a domain name"
        exit 1
    fi
    email=$2
    if [ -z "$email" ]; then
        echo "please supply an email address"
        exit 1
    fi
    if [ -f "/etc/letsencrypt/live/$domain/cert.pem" ]; then
        echo "certificate already exists, revoke it first"
        exit 1
    fi

    if [ "$3" == "live" ]; then
        certtype=""
    else
        certtype="--test-cert"
    fi
    certbot certonly --webroot -w "/var/www/letsencrypt/" -d $domain  $certtype  --email $email --agree-tos -n
    # Make sure nginx picks upthe new cerficate
    service nginx reload
elif [ "$1" = "revokecert" ]; then
    shift
    domain=$1
    if [ -z "$domain" ]; then
        echo "please supply a domain name"
        exit 1
    fi
    if [ ! -f "/etc/letsencrypt/live/$domain/cert.pem" ]; then
        echo "certificate does not exist"
        exit 1
    fi
    if [ "$2" == "live" ]; then
        certtype=""
    else
        certtype="--test-cert"
    fi
    certbot revoke  --cert-path "/etc/letsencrypt/live/$domain/cert.pem"  $certtype  -n
    service nginx reload
elif [ "$1" = "ssl" ]; then
    if [ -z "$3" ]; then
        echo "please supply a domain name"
        exit 1
    fi
    domain=$3
    if [ ! -f "/etc/nginx/sites-available/${domain}.conf" ]; then
        echo "domain vhost $domain does not exist"
        echo "make sure you have created with with \"vhost.sh create ...\" first."
        exit 1
    fi
    if [ "$2" = "enable" ]; then
        domain=$3
        # check if certificate exists first
        if [ ! -f "/etc/letsencrypt/live/$domain/cert.pem" ]; then
            echo "certificate must exist first"
            exit 1
        else 
            func_redirect_conf $domain > /etc/nginx/sites-available/$domain.conf 
            func_ssl $domain >> /etc/nginx/sites-available/$domain.conf 
            echo "ssl vhost installed";
            service nginx reload
        fi
    elif [ "$2" = "disable" ]; then
        domain=$3
        func_nginx_conf $domain > /etc/nginx/sites-available/$domain.conf 
        service nginx reload
        echo "removed ssl vhost for $domain"
    fi
else
    # usage
    cat <<done
usage:
    sudo vhost.sh [create|recreate|destroy|enable|disable] <domain>
    sudo vhost.sh ssl [enable|disable] <domain>
    sudo vhost.sh list
    sudo vhost.sh getcert <domain> <email> [live]
    sudo vhost.sh revokecert <domain> [live]
done

fi 
