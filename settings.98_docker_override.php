<?php

$settings['config_sync_directory'] = getenv("CONFIG_SYNC_DIRECTORY");
$settings['hash_salt'] = getenv("HASH_SALT");
$settings['trusted_host_patterns'] = $_ENV["TRUSTED_HOST_PATTERNS"];
$settings['state_cache'] = getenv("STATE_CACHE");
die(">>>" . $settings['trusted_host_patterns']);

// ls /opt/drupal/web/sites/default