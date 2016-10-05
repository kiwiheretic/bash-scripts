#!/bin/bash
# designed for ubuntu 16.04 DigitalOcean install
archive=$1
domain=$2
rm -fr ~/$domain/*
if [ -z "$archive" ] || [ -z "$domain" ]; then
    echo "usage: unpacktar <archive> <domain>"
    return
fi
( cd ~/$domain && tar -xvzf ~/${archive} --strip-components=1 && \
chown -R www-data.www-data * && chmod -R g+rw * )
chown www-data.www-data ~/$domain
service php7.0-fpm restart
