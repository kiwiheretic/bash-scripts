#!/bin/bash
function unpacktar() {
    archive=$1
    domain=$2
    rm -fr ~/$domain/*
    if [ -z "$archive" ] || [ -z "$domain" ]; then
        echo "usage: unpacktar <archive> <domain>"
        return
    fi
    ( cd ~/$domain && tar -xvzf ~/${archive}.tar.gz --strip-components=1 && \
    chown -R www-data.www-data * && chmod -R g+rw * )
    chown www-data.www-data ~/$domain
    service php5-fpm restart
}

function testgzip () {
    curl -H "Accept-Encoding: gzip" -I http://$1
}

function getcerttest() {
    letsencrypt --staging --webroot certonly -w /var/www/letsencrypt/ -d $1
}

function getcertlive() {
    letsencrypt  --webroot certonly -w /var/www/letsencrypt/ -d $1
}

function testcert() {
    curl --insecure -vvI https://$1 2>&1 | grep -e "Server certificate" -A6
}
