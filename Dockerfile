FROM kimai/kimai-base:fpm AS base

ENV MYSQL_DATABASE=drupal
ENV MYSQL_USER=drupal
ENV MYSQL_PASSWORD=drupal
ENV MYSQL_HOST=db
ENV MYSQL_PORT=3306
ENV CONFIG_SYNC_DIRECTORY='/opt/config-sync'
ENV HASH_SALT='abcde-change-me-plaese-12345'
ENV TRUSTED_HOST_PATTERNS="['^norwichrugby\.org$','^.+\.norwichrugby\.com$']"
ENV STATE_CACHE='TRUE'

WORKDIR /opt/drupal
RUN apk add --no-cache git openssh
RUN git clone https://github.com/NRFC/drupal.git /opt/drupal
RUN mkdir /opt/config-sync

RUN composer install

ENTRYPOINT [ "php-fpm" ]

FROM base AS dev
RUN composer install --dev
RUN rm /opt/drupal/web/sites/default/settings.10_prod.php

FROM base AS prod


#if (file_exists($app_root . '/' . $site_path . '/settings.local.php')) {
#  include $app_root . '/' . $site_path . '/settings.local.php';
#}

ENTRYPOINT [ "bash" ]

# docker build -t nrfc/www .
