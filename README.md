# bash-scripts

To install:

```
$ sudo apt-get install letsencrypt
$ sudo apt-get install git  
$ git clone https://github.com/kiwiheretic/bash-scripts.git ~/bash_scripts
$ sudo ./install.sh

Then add all vhost users to the vhost group

$ sudo usermod -a -G vhost <username>

replacing <username> with your username



Then logout and login again.

### webserver templates

To see what host templates are installed

$ vhost.sh templates list

### Virtual Hosts

To create a virtual host:

$ vhost.sh create <template-name> <domain>

To remove a virtual host:
$ vhost.sh destroy <domain>
Warning:  This removes all files from your webserver permanently!

If you just want to temporarily disable a virtual host:  
$ vhost.sh disable <domain>

To reenable a previously disabled virtual host:  
$ vhost.sh enable <domain>

### SSL
To create a test SSL certificate:  
$ getcerttest <domain>

To create a live SSL certificate:  
$ getcertlive <domain>

To add SSL certificate to your site  

$ vhost.sh create php-ssl  <domain>  

To remove SSL certificate to your site (but doesn't destroy certificate)  

$ vhost.sh ssl create php  <domain>  
Certificates are obtained from letsencrypt.org.  

