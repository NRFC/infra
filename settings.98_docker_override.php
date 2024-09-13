<?php

$settings['config_sync_directory'] = $_ENV["CONFIG_SYNC_DIRECTORY"];
$settings['hash_salt'] = $_ENV["HASH_SALT"];
$settings['trusted_host_patterns'] = json_decode($_ENV["TRUSTED_HOST_PATTERNS"], true);
$settings['state_cache'] = $_ENV["STATE_CACHE"];
