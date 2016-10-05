#!/bin/bash
# nullglob to allow for testing if file exists
shopt -s nullglob # enable

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
    cat > /usr/share/nginx/html/$domain/splats-test-page.html << done
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
    ln -s /usr/share/nginx/html/$domain/ ~/$domain
    cat > /etc/nginx/sites-available/ssl/$domain.conf << done
# Automatically created by vhost.sh script
# This file will be overwritten every time this script runs!!
server {
    listen 80;
    server_name www.$domain;
    return 301 \$scheme://$domain\$request_uri;
}
done
    cat > /etc/nginx/sites-available/$domain.conf << done

include sites-available/ssl/${domain}.conf;


server {
    listen       80;
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
    ln -s /etc/nginx/sites-available/$domain.conf  /etc/nginx/sites-enabled/$domain.conf
    service nginx reload
    echo "vhost $domain created and enabled"

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
    rm /etc/nginx/sites-enabled/ssl/$2.conf 2>/dev/null
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
        f=${f##*/}
        # check if file ends in .ssl.conf and otherwise
        # ignore it
        if [ -L "/etc/nginx/sites-enabled/$f" ]; then
            enabled="(enabled)"
        else
            enabled=""
        fi
        f=${f%.conf}
        echo $f $enabled
    done
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
        # find newest certificate path for this certificate
        certpath=$(find /etc/letsencrypt/live/ -type d -name "$domain*" -printf "%T@ %p\n" | sort -nr | cut -d\  -f2 | head -n1)
        # remove preceding path info
        if [ ! -z "$certpath" ]; then
 
            cat > /etc/nginx/sites-available/ssl/$domain.conf << done
# Automatically created by vhost.sh script
# This file will be overwritten every time this script runs!!
server {
    listen 80;
    listen 443 ssl;
    server_name www.$domain;
    return 301 \$scheme://$domain\$request_uri;
}

server {
    listen       443 ssl;
    server_name  $domain;
    ssl_certificate $certpath/fullchain.pem;
    ssl_certificate_key $certpath/privkey.pem;

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
        fastcgi_pass   unix:/var/run/php5-fpm.sock;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        include        fastcgi_params;
    }
}
done
            echo "ssl vhost installed";
            service nginx reload
        else
            echo "run \"getcertlive <domain>\" or"
            echo "\"getcerttest <domain>\" first"
        fi
    elif [ "$2" = "disable" ]; then
        domain=$3
        cat > /etc/nginx/sites-available/ssl/$domain.conf << done
# Automatically created by vhost.sh script
# This file will be overwritten every time this script runs!!
server {
    listen 80;
    server_name www.$domain;
    return 301 \$scheme://$domain\$request_uri;
}
done
        service nginx reload
        echo "removed ssl vhost for $domain"
    fi
else
    echo "unknown option: $1"
fi 
