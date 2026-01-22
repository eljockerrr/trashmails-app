FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    git unzip zip libzip-dev libpng-dev libonig-dev libxml2-dev \
    && docker-php-ext-install pdo_mysql mbstring zip

RUN a2enmod rewrite

WORKDIR /var/www/html
COPY . .

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer install --no-dev --optimize-autoloader

RUN cp .env.example .env || true
RUN php artisan key:generate || true

# ✅ Fix permissions (strong)
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R ug+rwX /var/www/html

# ✅ (Optional but fixes your exact error) make that package path writable
RUN chmod -R ug+rwX /var/www/html/vendor/artisync/image/src || true

EXPOSE 80
