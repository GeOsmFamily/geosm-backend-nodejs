FROM keopx/apache-php:7.3
# Set working directory
WORKDIR /var/www

RUN wget -O - http://qgis.org/downloads/qgis-2020.gpg.key | gpg --import

RUN gpg --fingerprint F7E06F06199EF2F2

RUN apt-get update

RUN gpg --export --armor F7E06F06199EF2F2 | apt-key add -

RUN apt-get update

RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    unzip \
    git \
    curl \
    libzip-dev \
    php7.3-pgsql\
    dos2unix

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://deb.nodesource.com/setup_11.x | bash - && apt-get install -y nodejs

RUN rm -rf /var/www/GeoOSM_Backend/ || true
RUN git clone https://github.com/GeOsm-Africa/geosm-backend.git ./GeoOSM_Backend
RUN cd /var/www/GeoOSM_Backend/ && composer install



RUN rm -rf /var/www/GeoOSM_Frontend/ || true
RUN git clone https://github.com/GeOsm-Africa/geoportail.git ./GeoOSM_Frontend
RUN cd /var/www/GeoOSM_Frontend/ && npm install

RUN rm -rf /var/www/backend_nodejs/ || true
RUN git clone https://github.com/GeOsm-Africa/geosm-backend-nodejs.git ./backend_nodejs
RUN cp /var/www/backend_nodejs/docker/boot.sh /var/www/
RUN rm -rf /var/www/backend_nodejs/ || true

RUN touch /var/www/GeoOSM_Backend/.env
RUN touch /var/www/GeoOSM_Backend/public/assets/config.js
RUN  chmod -R 777 /var/www/GeoOSM_Backend/
RUN ["chmod", "+x", "/var/www/boot.sh"]
