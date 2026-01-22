FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    git unzip zip libzip-dev libpng-dev libonig-dev libxml2-dev \
    && docker-php-ext-install pdo_mysql mbstring zip

RUN a2enmod rewrite

WORKDIR /var/www/html
COPY . .

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Create .env and app key (safe if already exists)
RUN cp .env.example .env || true
RUN php artisan key:generate || true

# ✅ Create Laravel required directories (sessions/cache/views/logs)
RUN mkdir -p /var/www/html/storage/framework/sessions \
    /var/www/html/storage/framework/views \
    /var/www/html/storage/framework/cache \
    /var/www/html/storage/logs

# ✅ Permissions for Laravel writable dirs
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R ug+rwX /var/www/html/storage /var/www/html/bootstrap/cache

# ✅ Runtime start script (fix permissions every start)
RUN printf '%s\n' \
'#!/bin/sh' \
'set -e' \
'mkdir -p /var/www/html/storage/framework/sessions /var/www/html/storage/framework/views /var/www/html/storage/framework/cache /var/www/html/storage/logs || true' \
'chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache || true' \
'chmod -R ug+rwX /var/www/html/storage /var/www/html/bootstrap/cache || true' \
'exec apache2-foreground' \
> /usr/local/bin/start.sh \
&& chmod +x /usr/local/bin/start.sh

EXPOSE 80
CMD ["/usr/local/bin/start.sh"]
