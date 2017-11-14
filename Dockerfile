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
    php7.1 \
    php7.1-mysql \
    php7.1-xml \
    php7.1-gd \
    php7.1-json \
    php7.1-curl \
    php7.1-mbstring \
    php7.1-opcache \
    php7.1-bz2 \
    php7.1-cli \
    php7.1-fpm \
    php7.1-common \
    php7.1-mcrypt \
    php7.1-dev \
    php7.1-phpdbg \
    php7.1-xml \
    php7.1-bcmath
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y nginx

#sleep 800000
RUN sleep 8000000
