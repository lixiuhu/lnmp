FROM phusion/baseimage

#install gcc g++ environment
RUN apt-get update
RUN apt-get install build-essential libtool -y

#install additional libraries
RUN apt-get install -y \
    libxml2-dev \
	libcurl4-openssl-dev \
	libjpeg-dev \
    libpng-dev \
    libxpm-dev \
    libmysqlclient-dev \
	libpq-dev \
	libicu-dev \
    libfreetype6-dev \
    libldap2-dev \
	libxslt-dev \
	mysql-client

#install pcre zlib ssl
RUN mkdir -p /home/tools && cd $_ && \
	curl -O ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.41.tar.gz && \
	tar -zxf pcre-8.41.tar.gz && cd  pcre-8.41 && \
	./configure && make && make install 
RUN cd /home/tools && \
	curl -O  http://zlib.net/zlib-1.2.11.tar.gz && \
	tar -zxf zlib-1.2.11.tar.gz && cd zlib-1.2.11 && \
	./configure && make && make install
RUN cd /home/tools && \
	http://www.openssl.org/source/openssl-1.0.2k.tar.gz && \
	tar -zxf openssl-1.0.2k.tar.gz && cd openssl-1.0.2k && \
	./configure && make && make install

RUN mkdir -p /home/nginx-php && cd $_ && \
	curl -Lk http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz | gunzip | tar x -C /home/nginx-php && \
	curl -Lk http://php.net/distributions/php-$PHP_VERSION.tar.gz | gunzip | tar x -C /home/nginx-php

#install nginx
RUN set -x && \
	cd /home/nginx-php/nginx-$NGINX_VERSION && \
	./configure --prefix=/usr/local/nginx \
	--user=www --group=www \
	--error-log-path=/var/log/nginx_error.log \
	--http-log-path=/var/log/nginx_access.log \
	--pid-path=/var/run/nginx.pid \
	--with-pcre=/home/tools/pcre-8.41 \
	--with-zlib=/home/tools/zlib-1.2.11 \
	--with-openssl=/home/tools/openssl-1.0.2k \
	--with-http_ssl_module \
	--without-mail_pop3_module \
	--without-mail_imap_module \
	--with-http_gzip_static_module && \
	make && make install


