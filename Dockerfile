FROM phusion/baseimage
# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

ENV HOME /root

RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

CMD ["/sbin/my_init"]

# Nginx-PHP Installation
RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y vim curl wget build-essential python-software-properties
RUN add-apt-repository -y ppa:nginx/stable
RUN add-apt-repository -y ppa:ondrej/php
RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y --force-yes \
    php7.1-mysql \
    php7.1-xml \
    php7.1-gd \
    php7.1-json \
    php7.1-curl \
    php7.1-mbstring \
    php7.1-opcache \
    php7.1-bz2 \
    php7.1-fpm \
    php7.1-common \
    php7.1-mcrypt \
    php7.1-dev \
    php7.1-xml \
    php7.1-bcmath
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y nginx

# Enable memcache
RUN set -x && \
    cd /usr/share/ && \
    wget https://github.com/php-memcached-dev/php-memcached/archive/php7.zip && \
    unzip php7.zip && rm php7.zip\
    cd php-memcached-php7 && \
    /usr/bin/phpize7.1 && \
    ./configure --with-php-config=/usr/bin/php-config7.1 && \
    make && \
    make install && \
    echo "extension=memcached.so" >> /etc/php/7.1/fpm/php.ini

# Enable redis
RUN set -x && \
    cd /usr/share/ && \
    wget https://github.com/phpredis/phpredis/archive/3.1.4.zip -O phpredis.zip && \
    unzip /root/phpredis.zip && rm phpredis.zip && \
    mv phpredis-* phpredis && cd phpredis && \
    /usr/bin/phpize7.1  && \
    ./configure --with-php-config=/usr/bin/php-config7.1 && \
    make && \
    make install && \
    echo extension=redis.so >> /etc/php/7.1/fpm/php.ini

# Changing php.ini
RUN set -x && \
    sed -i 's/memory_limit = .*/memory_limit = 1024M/' /etc/php/7.1/fpm/php.ini && \
    sed -i 's/post_max_size = .*/post_max_size = 32M/' /etc/php/7.1/fpm/php.ini && \
    sed -i 's/upload_max_filesize = .*/upload_max_filesize = 32M/' /etc/php/7.1/fpm/php.ini && \
    sed -i 's/post_max_size = .*/post_max_size = 32M/' /etc/php/7.1/fpm/php.ini && \
    sed -i 's/^; max_input_vars =.*/max_input_vars =10000/' /etc/php/7.1/fpm/php.ini && \
    echo zend_extension=opcache.so >> /etc/php/7.1/fpm/php.ini && \
    sed -i 's/^;cgi.fix_pathinfo =.*/cgi.fix_pathinfo = 0;/' /etc/php/7.1/fpm/php.ini

# Chaning timezone
RUN set -x && \
    unlink /etc/localtime && \
    ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

#Change Mod from webdir
RUN set -x && \
    chown -R www-data:www-data /var/www/html
    #Install supervisor

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

#Set port
EXPOSE 80 443

#Start it
ENTRYPOINT ["/var/www/startup.sh"]

#Start web server
#CMD ["/bin/bash", "/startup.sh"]

# Setting working directory
WORKDIR /var/www/html

#sleep 800000
