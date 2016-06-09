FROM debian:jessie

MAINTAINER Robin Thoni <robin@rthoni.com>

# Build php
# ======================================================================================================================

ENV PHPIZE_DEPS \
            autoconf \
            file \
            g++ \
            gcc \
            libc-dev \
            make \
            pkg-config \
            re2c
RUN apt-get update \
        && apt-get install -y \
		    $PHPIZE_DEPS \
		    ca-certificates \
		    curl \
		    libedit2 \
		    libsqlite3-0 \
		    libxml2 \
	        --no-install-recommends \
	    && rm -r /var/lib/apt/lists/*

ENV PHP_INI_DIR /etc/php7.0
RUN mkdir -p $PHP_INI_DIR/conf.d

RUN apt-get update \
        && apt-get install -y apache2-bin apache2.2-common --no-install-recommends \
        && rm -rf /var/lib/apt/lists/*

RUN rm -rf /var/www/html \
        && mkdir -p /var/lock/apache2 /var/run/apache2 /var/log/apache2 /var/www/html \
        && chown -R www-data:www-data /var/lock/apache2 /var/run/apache2 /var/log/apache2 /var/www/html

RUN a2dismod mpm_event \
        && a2enmod mpm_prefork

RUN mv /etc/apache2/apache2.conf /etc/apache2/apache2.conf.dist \
        && rm /etc/apache2/conf-enabled/* /etc/apache2/sites-enabled/*
COPY apache2.conf /etc/apache2/apache2.conf

ENV PHP_EXTRA_BUILD_DEPS apache2-dev
ENV PHP_EXTRA_CONFIGURE_ARGS --with-apxs2 --enable-maintainer-zts --enable-pthreads

ENV GPG_KEYS 1A4E8B7277C42E53DBA9C7B9BCAA30EA9C0D5763

ENV PHP_VERSION 7.0.7
ENV PHP_FILENAME php-7.0.7.tar.xz
ENV PHP_SHA256 9cc64a7459242c79c10e79d74feaf5bae3541f604966ceb600c3d2e8f5fe4794

RUN set -xe \
        && buildDeps=" \
            $PHP_EXTRA_BUILD_DEPS \
            libcurl4-openssl-dev \
            libedit-dev \
            libsqlite3-dev \
            libssl-dev \
            libxml2-dev \
            xz-utils \
        " \
        && apt-get update \
        && apt-get install -y $buildDeps --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* \
        && curl -fSL "http://php.net/get/$PHP_FILENAME/from/this/mirror" -o "$PHP_FILENAME" \
        && echo "$PHP_SHA256 *$PHP_FILENAME" | sha256sum -c - \
        && curl -fSL "http://php.net/get/$PHP_FILENAME.asc/from/this/mirror" -o "$PHP_FILENAME.asc" \
        && export GNUPGHOME="$(mktemp -d)" \
        && for key in $GPG_KEYS; do \
            gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
            done \
        && gpg --batch --verify "$PHP_FILENAME.asc" "$PHP_FILENAME" \
        && rm -r "$GNUPGHOME" "$PHP_FILENAME.asc" \
        && mkdir -p /usr/src/php \
        && tar -xf "$PHP_FILENAME" -C /usr/src/php --strip-components=1 \
        && rm "$PHP_FILENAME" \
        && cd /usr/src/php \
        && ./configure \
            --with-config-file-path="$PHP_INI_DIR" \
            --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
            $PHP_EXTRA_CONFIGURE_ARGS \
            --disable-cgi \
            --enable-mysqlnd \
            --enable-mbstring \
            --with-curl \
            --with-libedit \
            --with-openssl \
            --with-zlib \
        && make -j"$(nproc)" \
        && make install \
        && { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; } \
        && make clean \
        && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $buildDeps

RUN ln -sf /dev/stdout /var/log/apache2/access.log \
        && ln -sf /dev/stderr /var/log/apache2/error.log \
        && ln -sf /dev/stdout /var/log/websocket.log \
        && ln -sf /dev/stderr /var/log/websocket.err \
        && a2enmod rewrite \
        && rm -rf /var/www/* \
        && chown -R www-data:www-data /var/www

RUN pecl install pthreads

# Install Composer
# ======================================================================================================================
RUN curl https://getcomposer.org/composer.phar -o /usr/local/bin/composer \
        && chmod +x /usr/local/bin/composer

RUN apt-get update \
        && apt-get install -y git unzip --no-install-recommends \
        && rm -rf /var/lib/apt/lists/*

# Add pdo and db drivers
# ======================================================================================================================

COPY docker-php-ext-* /usr/local/bin/

RUN buildDeps="libpq-dev libzip-dev " \
        && apt-get update \
        && apt-get install -y $buildDeps --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* \
        && docker-php-ext-install pdo pdo_pgsql pgsql

# Install PHP config files
# ======================================================================================================================

COPY php-cli.ini "${PHP_INI_DIR}"/
COPY php-apache.ini "${PHP_INI_DIR}"/php-apache2handler.ini

# Run everything
# ======================================================================================================================

COPY run.sh /usr/local/bin/

WORKDIR /var/www

EXPOSE 8180
EXPOSE 80
VOLUME ["/var/www"]
CMD ["run.sh"]
