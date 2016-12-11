# bash-scripts

To install:

```
$ sudo apt-get install git  
$ git clone https://github.com/kiwiheretic/bash-scripts.git
$ sudo cp -v bash\_scripts/\*.conf  /etc/nginx
$ sudo mkdir /var/www/letsencrypt
$ sudo mkdir /etc/nginx/sites-available/ssl

$ ln -s bash\_scripts/vhost.sh ~/vhost.sh
$ ln -s bash\_scripts/unpacktar.sh ~/unpacktar.sh
```

Either add the following command to ~/.bashrc with editor or invoke from command line on login

```
$ source ~/bash\_scripts/cert\_fns.sh
```
