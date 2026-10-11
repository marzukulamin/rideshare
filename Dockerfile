FROM php:8.3-apache

RUN docker-php-ext-install pdo_mysql mysqli \
    && a2enmod rewrite headers

WORKDIR /var/www/html
COPY public/ /var/www/html/
COPY src/ /var/www/src/

RUN printf '<Directory /var/www/html>\n    AllowOverride All\n    Require all granted\n</Directory>\n' > /etc/apache2/conf-available/rideshare.conf \
    && a2enconf rideshare

EXPOSE 80
