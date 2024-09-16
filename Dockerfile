ARG PHP_VER="8.3"
ARG COMPOSER_VER="latest"
ARG TIMEZONE="Europe/London"

###########################
# Shared tools
###########################

# composer base image
FROM composer:${COMPOSER_VER} AS composer

###########################
# PHP extensions
###########################

# apache debian php extension base
FROM php:${PHP_VER}-apache-bookworm AS apache-php-ext-base
RUN apt-get update
RUN apt-get install -y \
        libavif-dev \
        libldap2-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libzip-dev \
        libxslt1-dev \
        libfreetype6-dev \
        libwebp-dev \
        libxpm-dev \
        git

FROM apache-php-ext-base AS git-src
RUN git clone https://github.com/NRFC/drupal.git /opt/drupal


# php extension gd - 13.86s
FROM apache-php-ext-base AS php-ext-gd
RUN docker-php-ext-configure gd \
        --with-freetype \
        --with-avif \
        --with-jpeg \
        --with-xpm \
        --with-webp && \
    docker-php-ext-install -j$(nproc) gd

# php extension intl : 15.26s
FROM apache-php-ext-base AS php-ext-intl
RUN docker-php-ext-install -j$(nproc) intl

# php extension ldap : 8.45s
FROM apache-php-ext-base AS php-ext-ldap
RUN docker-php-ext-configure ldap && \
    docker-php-ext-install -j$(nproc) ldap

# php extension pdo_mysql : 6.14s
FROM apache-php-ext-base AS php-ext-pdo_mysql
RUN docker-php-ext-install -j$(nproc) pdo_mysql

# php extension zip : 8.18s
FROM apache-php-ext-base AS php-ext-zip
RUN docker-php-ext-install -j$(nproc) zip

# php extension xsl : ?.?? s
FROM apache-php-ext-base AS php-ext-xsl
RUN docker-php-ext-install -j$(nproc) xsl

# php extension redis
FROM apache-php-ext-base AS php-ext-redis
RUN yes no | pecl install redis && \
    docker-php-ext-enable redis

# php extension opcache
FROM apache-php-ext-base AS php-ext-opcache
RUN docker-php-ext-install -j$(nproc) opcache


###########################
# apache base build
###########################

FROM php:${PHP_VER}-apache-bookworm AS apache-base
ARG TIMEZONE
RUN apt-get update && \
    apt-get install -y \
        bash \
        haveged \
        libavif-bin \
        libjpeg62-turbo-dev \
        libicu72 \
        libldap-common \
        libpng16-16 \
        libzip4 \
        libxslt1.1 \
        libfreetype6 \
        libwebp7 \
        libxpm4 && \
    a2enmod rewrite

EXPOSE 80

HEALTHCHECK --interval=20s --timeout=10s --retries=3 \
    CMD curl -f http://127.0.0.1:8001 || exit 1

###########################
# global base build
###########################

FROM apache-base AS base
ARG TIMEZONE

ENV TIMEZONE=${TIMEZONE}
RUN ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo ${TIMEZONE} > /etc/timezone

# copy php extensions

# PHP extension xsl
COPY --from=php-ext-xsl /usr/local/etc/php/conf.d/docker-php-ext-xsl.ini /usr/local/etc/php/conf.d/docker-php-ext-xsl.ini
COPY --from=php-ext-xsl /usr/local/lib/php/extensions/no-debug-non-zts-20230831/xsl.so /usr/local/lib/php/extensions/no-debug-non-zts-20230831/xsl.so
# PHP extension pdo_mysql
COPY --from=php-ext-pdo_mysql /usr/local/etc/php/conf.d/docker-php-ext-pdo_mysql.ini /usr/local/etc/php/conf.d/docker-php-ext-pdo_mysql.ini
COPY --from=php-ext-pdo_mysql /usr/local/lib/php/extensions/no-debug-non-zts-20230831/pdo_mysql.so /usr/local/lib/php/extensions/no-debug-non-zts-20230831/pdo_mysql.so
# PHP extension zip
COPY --from=php-ext-zip /usr/local/etc/php/conf.d/docker-php-ext-zip.ini /usr/local/etc/php/conf.d/docker-php-ext-zip.ini
COPY --from=php-ext-zip /usr/local/lib/php/extensions/no-debug-non-zts-20230831/zip.so /usr/local/lib/php/extensions/no-debug-non-zts-20230831/zip.so
# PHP extension ldap
COPY --from=php-ext-ldap /usr/local/etc/php/conf.d/docker-php-ext-ldap.ini /usr/local/etc/php/conf.d/docker-php-ext-ldap.ini
COPY --from=php-ext-ldap /usr/local/lib/php/extensions/no-debug-non-zts-20230831/ldap.so /usr/local/lib/php/extensions/no-debug-non-zts-20230831/ldap.so
# PHP extension gd
COPY --from=php-ext-gd /usr/local/etc/php/conf.d/docker-php-ext-gd.ini /usr/local/etc/php/conf.d/docker-php-ext-gd.ini
COPY --from=php-ext-gd /usr/local/lib/php/extensions/no-debug-non-zts-20230831/gd.so /usr/local/lib/php/extensions/no-debug-non-zts-20230831/gd.so
# PHP extension intl
COPY --from=php-ext-intl /usr/local/etc/php/conf.d/docker-php-ext-intl.ini /usr/local/etc/php/conf.d/docker-php-ext-intl.ini
COPY --from=php-ext-intl /usr/local/lib/php/extensions/no-debug-non-zts-20230831/intl.so /usr/local/lib/php/extensions/no-debug-non-zts-20230831/intl.so
# PHP extension redis
COPY --from=php-ext-redis /usr/local/etc/php/conf.d/docker-php-ext-redis.ini /usr/local/etc/php/conf.d/docker-php-ext-redis.ini
COPY --from=php-ext-redis /usr/local/lib/php/extensions/no-debug-non-zts-20230831/redis.so /usr/local/lib/php/extensions/no-debug-non-zts-20230831/redis.so
COPY --from=php-ext-opcache /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini  /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini

COPY --from=git-src /opt/drupal /opt/drupal
WORKDIR /opt/drupal

########################
# composer build
########################
FROM base AS composer-base
COPY --from=composer /usr/bin/composer /usr/bin/composer
RUN apt update
RUN apt install -y git npm
RUN npm install -g corepack
RUN corepack prepare yarn@stable --activate
RUN mkdir -p /composer
RUN chown -R www-data:www-data /composer
RUN composer install --no-ansi
RUN yarn --cwd /opt/drupal/web/themes/custom/nrfc_barrio
RUN /opt/drupal/web/themes/custom/nrfc_barrio/node_modules/.bin/gulp --cwd /opt/drupal/web/themes/custom/nrfc_barrio styles
RUN /opt/drupal/web/themes/custom/nrfc_barrio/node_modules/.bin/gulp --cwd /opt/drupal/web/themes/custom/nrfc_barrio js

########################
# final build
########################
FROM base AS prod

COPY --from=composer-base /opt/drupal /opt/drupal
COPY 000-apache.conf /etc/apache2/sites-enabled/000-default.conf
COPY settings.98_docker_override.php /opt/drupal/web/sites/default/settings.98_docker_override.php
COPY settings.99_db.php /opt/drupal/web/sites/default/settings.99_db.php

RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini && \
    sed -i "s/2M/16M/" /usr/local/etc/php/php.ini && \
    sed -i "s/8M/16M/" /usr/local/etc/php/php.ini && \
    sed -i 's/"GPCS"/"EGPCS"/' /usr/local/etc/php/php.ini

ENV MYSQL_DATABASE=drupal
ENV MYSQL_USER=drupal
ENV MYSQL_PASSWORD=""
ENV MYSQL_HOST=db
ENV MYSQL_PORT=3306
ENV CONFIG_SYNC_DIRECTORY='/opt/config-sync'
ENV HASH_SALT='abcde-change-me-plaese-12345'
ENV TRUSTED_HOST_PATTERNS="['^norwichrugby\.org$','^.+\.norwichrugby\.com$']"
ENV STATE_CACHE='TRUE'

# docker build -t tobybatch/nrfc .
# docker push tobybatch/nrfc