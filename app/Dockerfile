FROM php:8.2-fpm-bookworm

RUN apt-get update \
    && apt-get install --yes --no-install-recommends libpq-dev \
    && docker-php-ext-install pdo_pgsql \
    && groupadd --system appgroup \
    && useradd --system --gid appgroup --no-create-home appuser \
    && apt-mark manual libpq5 \
    && apt-get purge --yes --auto-remove libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html
COPY --chown=appuser:appgroup public/ /var/www/html/
COPY php.ini /usr/local/etc/php/conf.d/security-lab.ini

USER appuser
EXPOSE 9000
