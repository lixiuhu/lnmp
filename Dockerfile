FROM phusion/baseimage

ENV NGINX_VERSION 1.12.2
ENV PHP_VERSION 7.1.11

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

ENV HOME /root

RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

CMD ["/sbin/my_init"]

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
	openssl 

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
	curl -O	http://www.openssl.org/source/openssl-1.0.2k.tar.gz && \
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
	--with-pcre \
	--with-http_ssl_module \
	--without-mail_pop3_module \
	--without-mail_imap_module \
	--with-http_gzip_static_module && \
	make && make install
#install php
  RUN set -x && \
      cd /home/nginx-php/php-$PHP_VERSION && \
      ./configure --prefix=/usr/local/php \
      --with-config-file-path=/usr/local/php/etc \
      --with-config-file-scan-dir=/usr/local/php/etc/php.d \
      --with-fpm-user=www \
      --with-fpm-group=www \
      --with-mcrypt=/usr/include \
      --with-mysqli \
      --with-pdo-mysql \
      --with-openssl \
      --with-gd \
      --with-iconv \
      --with-zlib \
      --with-gettext \
      --with-curl \
      --with-png-dir \
      --with-jpeg-dir \
      --with-freetype-dir \
      --with-xmlrpc \
      --with-mhash \
      --with-memcached \
      --enable-bcmath \
      --enable-fpm \
      --enable-xml \
      --enable-shmop \
      --enable-sysvsem \
      --enable-inline-optimization \
      --enable-mbregex \
      --enable-mbstring \
      --enable-ftp \
      --enable-gd-native-ttf \
      --enable-mysqlnd \
      --enable-pcntl \
      --enable-sockets \
      --enable-zip \
      --enable-soap \
      --enable-session \
      --enable-opcache \
      --enable-bcmath \
      --enable-exif \
      --enable-fileinfo \
      --disable-rpath \
      --enable-ipv6 \
      --disable-debug \
      --without-pear && \
      make && make install



#Install php-fpm
RUN set -x && \
    cd /home/nginx-php/php-$PHP_VERSION && \
    cp php.ini-production /usr/local/php/etc/php.ini && \
    cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf && \
    cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf

# Enable memcache
RUN set -x && \
    mkdir -p /usr/local/src/php-memcache && \
    cd /usr/local/src/php-memcache && \
    wget https://github.com/php-memcached-dev/php-memcached/archive/php7.zip && \
    unzip php7.zip && \
    cd php-memcached-php7 && \
    /usr/local/php/bin/phpize && \
    ./configure --with-php-config=/usr/local/php/bin/php-config && \
    # --disable-memcached-sasl && \
    make && \
    make install && \
    echo "extension=memcached.so" >> /usr/local/php/etc/php.ini

# Enable redis
RUN set -x && \
    cd /root && \
    wget https://github.com/phpredis/phpredis/archive/3.1.4.zip -O phpredis.zip && \
    #wget https://github.com/phpredis/phpredis/archive/master.zip -O phpredis.zip && \
    unzip -o /root/phpredis.zip && \
    mv /root/phpredis-* /root/phpredis && \
    cd /root/phpredis && \
    /usr/local/php/bin/phpize && \
    ./configure --with-php-config=/usr/local/php/bin/php-config && \
    make && \
    make install && \
    echo extension=redis.so >> /usr/local/php/etc/php.ini

# Changing php.ini
RUN set -x && \
    sed -i 's/memory_limit = .*/memory_limit = 1024M/' /usr/local/php/etc/php.ini && \
    sed -i 's/post_max_size = .*/post_max_size = 32M/' /usr/local/php/etc/php.ini && \
    sed -i 's/upload_max_filesize = .*/upload_max_filesize = 32M/' /usr/local/php/etc/php.ini && \
    sed -i 's/post_max_size = .*/post_max_size = 32M/' /usr/local/php/etc/php.ini && \
    sed -i 's/^; max_input_vars =.*/max_input_vars =10000/' /usr/local/php/etc/php.ini && \
    echo zend_extension=opcache.so >> /usr/local/php/etc/php.ini && \
    sed -i 's/^;cgi.fix_pathinfo =.*/cgi.fix_pathinfo = 0;/' /usr/local/php/etc/php.ini

# Enable opcache php.ini
RUN set -x && \
    sed -i 's/^;opcache.enable=.*/opcache.enable=1/' /usr/local/php/etc/php.ini && \
    sed -i 's/^;opcache.memory_consumption=.*/opcache.memory_consumption=256/' /usr/local/php/etc/php.ini && \
    sed -i 's/^;opcache.interned_strings_buffer=.*/opcache.interned_strings_buffer=8/' /usr/local/php/etc/php.ini && \
    sed -i 's/^;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=4000/' /usr/local/php/etc/php.ini && \
    sed -i 's/^;opcache.revalidate_freq=.*/opcache.revalidate_freq=60/' /usr/local/php/etc/php.ini && \
    sed -i 's/^;opcache.fast_shutdown=.*/opcache.fast_shutdown=1/' /usr/local/php/etc/php.ini && \
    sed -i 's/^;opcache.enable_cli=.*/opcache.enable_cli=1/' /usr/local/php/etc/php.ini

# Changing php-fpm configureations
RUN set -x && \
    sed -i 's/listen = .*/listen = \/var\/run\/php-fpm-www.sock/' /usr/local/php/etc/php-fpm.d/www.conf && \
    sed -i 's/;listen.owner = www/listen.owner = www/' /usr/local/php/etc/php-fpm.d/www.conf && \
    sed -i 's/;listen.group = www/listen.group = www/' /usr/local/php/etc/php-fpm.d/www.conf && \
    sed -i 's/;listen.mode = 0660/listen.mode = 0660/' /usr/local/php/etc/php-fpm.d/www.conf

#Install supervisor
RUN set -x && \
    easy_install supervisor && \
    mkdir -p /var/{log/supervisor,run/{sshd,supervisord}}

#Clean OS

# Chaning timezone
RUN set -x && \
    unlink /etc/localtime && \
    ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

#Change Mod from webdir
RUN set -x && \
    chown -R www:www /var/www/html

# Insert supervisord conf file
ADD supervisord.conf /etc/

#Create web folder,mysql folder
VOLUME ["/var/www/html", "/usr/local/nginx/conf/ssl", "/usr/local/nginx/conf/vhost", "/usr/local/php/etc/php.d", "/var/www/phpext"]

ADD index.php /var/www/html

ADD extfile/ /var/www/phpext/

#Update nginx config
ADD nginx.conf /usr/local/nginx/conf/

#ADD ./scripts/docker-entrypoint.sh /docker-entrypoint.sh
#ADD ./scripts/docker-install.sh /docker-install.sh

#Start
ADD startup.sh /var/www/startup.sh
RUN chmod +x /var/www/startup.sh

ENV PATH /usr/local/php/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN set -x && \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    composer global require drush/drush:~8 && \
    sed -i '1i export PATH="$HOME/.composer/vendor/drush/drush:$PATH"' $HOME/.bashrc && \
    source $HOME/.bashrc

RUN yum install -y which

RUN rpm -Uvh http://yum.newrelic.com/pub/newrelic/el5/x86_64/newrelic-repo-5-3.noarch.rpm
RUN yum install -y yum install newrelic-php5

#RUN chmod +x /docker-entrypoint.sh
#RUN chmod +x /docker-install.sh
#Set port
EXPOSE 80 443

#Start it
ENTRYPOINT ["/var/www/startup.sh"]

#Start web server
#CMD ["/bin/bash", "/startup.sh"]

# Setting working directory
WORKDIR /var/www/html
