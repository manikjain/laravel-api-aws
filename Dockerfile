# Dockerfile
FROM php:8.1-cli

RUN apt-get update -y && apt-get install -y zip

WORKDIR /app
COPY . /app

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    php composer-setup.php \
    php -r "unlink('composer-setup.php');"
# RUN docker-php-ext-install pdo mbstring
RUN docker-php-ext-install pdo mysqli pdo_mysql

ENV COMPOSER_ALLOW_SUPERUSER=1

RUN ./composer.phar create-project joselfonseca/laravel-api new-api

WORKDIR new-api

RUN sed -i -e "23,27s/^/#/g" -e "s/DB_PASSWORD=/DB_PASSWORD=password/g" -e "11s/DB_HOST=127\.0\.0\.1/DB_HOST=mysql/g" .env

EXPOSE 8000
CMD ["sh", "-c", "sleep 10 && php artisan migrate && php artisan passport:install && php artisan db:seed && php artisan serve --host=0.0.0.0 --port=8000"]
