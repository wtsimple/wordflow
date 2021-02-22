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
# Install Fail2ban although I really think it should be on your server outside the container
RUN apt-get install -y fail2ban
# redis
RUN apt-get install -y redis
# set the nginx configs
COPY ./nginx/ /etc/nginx/
RUN ln -s /etc/nginx/sites-available/rocketstack.conf /etc/nginx/sites-enabled/
RUN rm /etc/nginx/sites-enabled/default

# Create needed folders
RUN mkdir -p /var/www/cache
RUN mkdir -p /var/www/cache/rocketstack
RUN mkdir -p /var/www/rocketstack
COPY ./bedrock/ /var/www/rocketstack
RUN chown www-data:www-data /var/www/ -R


CMD service nginx restart && service php7.3-fpm start && redis-server /usr/local/etc/redis/redis.conf  && tail -f /dev/null