FROM ubuntu:18.04
RUN apt-get update
RUN apt install -y software-properties-common
RUN apt install -y apt-utils
# Install PHP packages
RUN add-apt-repository ppa:ondrej/php
RUN DEBIAN_FRONTEND="noninteractive" TZ="Europe/London" apt-get -y install php7.3
RUN apt-get purge apache2 -y
RUN apt-get install nginx -y
RUN apt-get install -y tmux curl wget php7.3-fpm php7.3-cli php7.3-curl php7.3-gd php7.3-intl
RUN apt-get install -y php7.3-mysql php7.3-mbstring php7.3-zip php7.3-xml unzip php7.3-soap php7.3-redis

# redis
RUN apt-get install -y redis
RUN mkdir -p /usr/local/etc/redis
COPY ./redis.conf /usr/local/etc/redis/redis.conf

# set the nginx configs
COPY ./nginx/ /etc/nginx/
RUN ln -s /etc/nginx/sites-available/rocketstack.conf /etc/nginx/sites-enabled/
RUN rm /etc/nginx/sites-enabled/default

#PHP FPM configs
COPY ./php.ini /etc/php/7.3/fpm/php.ini

# Create needed folders
RUN mkdir -p /var/www/cache
RUN mkdir -p /var/www/cache/rocketstack
RUN mkdir -p /var/www/rocketstack
COPY ./bedrock/ /var/www/rocketstack
RUN chmod a+rwx -R /var/www/

# Letsencrypt ssl
#RUN add-apt-repository -y universe
#RUN add-apt-repository -y ppa:certbot/certbot
#RUN apt-get install -y python-certbot-nginx
#RUN certbot --nginx --non-interactive --agree-tos -m armando.rivero143@gmail.com -d precisalingua.com

CMD service nginx restart && service php7.3-fpm start && redis-server /usr/local/etc/redis/redis.conf  && tail -f /dev/null