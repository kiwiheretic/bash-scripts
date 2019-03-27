# bash-scripts

To install:

```
$ sudo apt-get install letsencrypt
$ sudo apt-get install git  
$ git clone https://github.com/kiwiheretic/bash-scripts.git ~/bash_scripts
$ sudo ./install.sh

Then add all vhost users to the vhost group

$ sudo usermod -a -G vhost &lt;username&gt;

replacing &lt;username&gt; with your username



Then logout and login again.

### webserver templates

To see what host templates are installed

$ vhost.sh templates list

### Virtual Hosts

To create a virtual host:

$ vhost.sh create &lt;template-name&gt; &lt;domain&gt;

To remove a virtual host:
$ vhost.sh destroy &lt;domain&gt;
Warning:  This removes all files from your webserver permanently!

If you just want to temporarily disable a virtual host:  
$ vhost.sh disable &lt;domain&gt;

To reenable a previously disabled virtual host:  
$ vhost.sh enable &lt;domain&gt;

### SSL
To create a test SSL certificate:  
$ getcerttest &lt;domain&gt;

To create a live SSL certificate:  
$ getcertlive &lt;domain&gt;

To add SSL certificate to your site  

$ vhost.sh create php-ssl  &lt;domain&gt;  

To remove SSL certificate to your site (but doesn't destroy certificate)  

$ vhost.sh ssl create php  &lt;domain&gt;  
Certificates are obtained from letsencrypt.org.  

