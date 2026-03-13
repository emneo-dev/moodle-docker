FROM php:8.1-fpm-alpine
# Yes I know this is EOL

ENV MOODLE_VERSION=4.1.22
ENV UPLOAD_MAX_FILESIZE=20M
ENV PHP_MEMORY_LIMIT=128M
ENV PHP_MAX_EXECUTION_TIME=30
ENV PHP_MAX_INPUT_VARS=6000

# Might want to look at compiling php from source: https://docs.moodle.org/401/en/Compiling_PHP_from_source

# All moodle documented required extensions + pgsql
# https://docs.moodle.org/401/en/PHP
# xmlrpc is unmaintained: https://php.watch/versions/8.0/xmlrpc
# it's also very much ass to install, so let's do without for now
# already included:
#   mbstring
#   curl
#   iconv
#   openssl
#   tokenizer
#   spl
#   ctype
#   simplexml
#   pcre
#   dom
#   xml
#   json
RUN apk update --no-cache \
    && apk add --no-cache nginx supervisor libxml2 libzip libpng icu libpq graphviz \
    && apk add --no-cache libxml2-dev libzip-dev libpng-dev icu-dev libpq-dev --virtual .build-deps \
    && docker-php-ext-install -j$(nproc) \
        soap \
        zip \
        gd \
        intl \
        pgsql \
        exif \
    && apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del --no-network .phpize-deps \
    && apk del --no-network .build-deps

RUN curl -L https://github.com/moodle/moodle/archive/v${MOODLE_VERSION}.tar.gz | tar xz --strip=1 \
    && mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && mkdir -p /moodledata /var/local/cache \
    && chown -R www-data /moodledata

# Configure moodle
COPY config/config.php /var/www/html/
COPY docker-entrypoint.sh /docker-entrypoint.sh

# Configure nginx - http
COPY config/nginx.conf /etc/nginx/nginx.conf
# Configure nginx - default server
COPY config/conf.d /etc/nginx/conf.d/

# Configure php-fpm
COPY config/fpm-pool.conf /usr/local/etc/php-fpm.d/zzzzz-www.conf
COPY config/php.ini ${PHP_INI_DIR}/conf.d/custom.ini

# Configure supervisord
# TODO: Get rid of supervisor -> Too much added to the image
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 80

# Let supervisord start nginx & php-fpm
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1/fpm-ping || exit 1
