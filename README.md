Docker for php 7.0 with apache 2.4
==================================

Why?
----

This docker file allows you to deploy a php 7.0 application in a couple of seconds on any server configuration. See docker help for more information.

Usage
-----

Build the image:
```shell
git clone https://git.rthoni.com/robin.thoni/docker-php7.0-apache
cd docker-php7.0-apache
docker build -t php7.0-apache .
```

Run a container:
```shell
docker run -d -v /path/to/my/php/application/:/var/www/html -p 8000:80 --name=container-my-php-application-apache php7.0-apache
```
NB: /path/to/my/application/public/ folder must exists

Browse:

Open https://127.0.0.1:8000/ in a web browser.
