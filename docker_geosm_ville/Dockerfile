FROM keopx/apache-php:7.4
# Set working directory
WORKDIR /var/www

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
    libzip4 \
    php7.4-pgsql\
    dos2unix \
    php7.4-gd



RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - && apt-get install -y nodejs

RUN rm -rf /var/www/GeoOSM_Backend/ || true
RUN git clone -b v8 https://github.com/GeOsmFamily/geosm-backend.git ./GeoOSM_Backend
RUN cd /var/www/GeoOSM_Backend && composer install

RUN rm -rf /var/www/GeoOSM_Frontend/ || true
RUN git clone  https://github.com/GeOsmFamily/geoportail-frontend-final.git ./GeoOSM_Frontend
RUN cd /var/www/GeoOSM_Frontend/ && npm install

RUN rm -rf /var/www/backend_nodejs/ || true
RUN git clone https://github.com/GeOsmFamily/geosm-backend-nodejs.git ./backend_nodejs
RUN cp /var/www/backend_nodejs/docker/boot.sh /var/www/
RUN rm -rf /var/www/backend_nodejs/ || true

RUN touch /var/www/GeoOSM_Backend/.env
RUN touch /var/www/GeoOSM_Backend/public/assets/config.js
RUN  chmod -R 777 /var/www/GeoOSM_Backend/
RUN ["chmod", "+x", "/var/www/boot.sh"]


