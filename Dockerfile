FROM phusion/baseimage

#install gcc g++ environment
RUN apt-get update
RUN apt-get install build-essential libtool -y
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

#
