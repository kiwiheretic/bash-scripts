# bash-scripts

To install:

```
$ sudo apt-get install letsencrypt
$ sudo apt-get install git  
$ git clone https://github.com/kiwiheretic/bash-scripts.git ~/bash_scripts
$ sudo cp -v ~/bash_scripts/*.conf  /etc/nginx
$ sudo mkdir /var/www/letsencrypt
$ sudo mkdir /etc/nginx/sites-available/ssl

$ ln -s ~/bash_scripts/vhost.sh ~/vhost.sh
$ ln -s ~/bash_scripts/unpacktar.sh ~/unpacktar.sh
```

Either add the following command to ~/.bashrc with editor or invoke from command line on login

```
$ echo "source ~/bash_scripts/cert_fns.sh" >> ~/.bashrc
```

Then logout and login again.

### Virtual Hosts

To create a virtual host:

vhost.sh create &lt;domain&gt;

To remove a virtual host:
vhost.sh destroy &lt;domain&gt;
Warning:  This removes all files from your webserver permanently!

If you just want to temporarily disable a virtual host:  
vhost.sh disable &lt;domain&gt;

To reenable a previously disabled virtual host:  
vhost.sh enable &lt;domain&gt;

### SSL
To create a test SSL certificate:  
getcerttest &lt;domain&gt;

To create a live SSL certificate:  
getcertlive &lt;domain&gt;

To add SSL certificate to your site  

vhost.sh ssl enable &lt;domain&gt;
To remove SSL certificate to your site (but doesn't destroy certificate)  

vhost.sh ssl disable &lt;domain&gt;
Certificates are obtained from letsencrypt.org.  

Only a small number (around 5) of live certificates can be obtained a week.  So best to test with test certificates until ready.  Test certificates will not
show as valid inside a browser.  To test the test certificate and indeed all certificates see below.

To test a domains certificates are installed:  
testcert &lt;domain&gt;
