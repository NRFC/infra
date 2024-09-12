<?php

$databases['default']['default'] = array (
  'database' => getenv("MYSQL_DATABASE"),
  'username' => getenv("MYSQL_USER"),
  'password' => getenv("MYSQL_PASSWORD"),
  'prefix' => '',
  'host' => getenv("MYSQL_HOST"),
  'port' => getenv("MYSQL_PORT"),
  'namespace' => 'Drupal\\mysql\\Driver\\Database\\mysql',
  'driver' => 'mysql',
  'autoload' => 'core/modules/mysql/src/Driver/Database/mysql/',
);
