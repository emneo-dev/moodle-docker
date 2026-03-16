# Moodle Docker

Specialized Docker image made to run docker with PostgreSQL and Redis.
nginx and php-fpm are included in the same image to run the whole application.

- Moodle: 4.1.22
- Alpine: 3.21
- PHP: 8.1

## PHP extensions

Here are the required extensions for this Moodle configuration to work:
- iconv - Already included in php
- mbstring - Already included in php
- curl - Already included in php
- openssl - Already included in php
- tokenizer - Already included in php
- xmlrpc - Not installed, as it is not maintained anymore and doesn't compile
- soap
- ctype - Already included in php
- zip
- gd
- simplexml - Already included in php
- spl - Already included in php
- pcre - Already included in php
- dom - Already included in php
- xml - Already included in php
- intl
- json - Already included in php
- pgsql

## New packages and libraries

Here are the packages added on top of the base php-fpm image to make this work:
- nginx
- libxml2 -> Needed for all of PHP's xml manipulations
- libzip -> Needed for PHP's zip extension
- libpng -> Needed for PHP's gd extension
- icu -> Needed for PHP's intl extension
- libpq -> Needed for PHP's pgsql extension

## Setting up Redis as the cache store

Follow this tutorial: <https://docs.moodle.org/401/en/Redis_cache_store>
