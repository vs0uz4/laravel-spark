# base image for PHP version 7.2
FROM php:7.2-apache
LABEL maintainer="PremiaLab"
LABEL author="Bryan Vaz"
USER root

# arguments for build
ARG DEBIAN_FRONTEND=noninteractive

# environment variables
ENV PHANTOMJS_VERSION 2.1.1-linux-x86_64
ENV NODE_VERSION 14.15.4
ENV YARN_VERSION 1.22.10
ENV COMPOSER_VERSION 2.0.8
ENV PECL_VERSION 5.1.19
ENV WKHTMLTOPDF_VERSION 0.12.3

# Node User
RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

# Add default apache configurations files, for define SERVER_NAME
ADD .docker/apache2.conf /etc/apache2/apache2.conf

# install all the system dependencies
# install apt-utils for workaround of missing ubuntu package
# install gpg to install nodejs and yarn from source
# install zip and unzip to install composer vendors
# install git to install dependencies from git repositories
# install wkhtmltopdf dependencies to convert html to pdf
RUN apt-get update && apt-get install -y \
      gnupg=2.2.12-1+deb10u1 \
      zip=3.0-11+b1\
      unzip=6.0-23+deb10u1 \
      git=1:2.20.1-2+deb10u3 \
      libfontconfig1=2.13.1-2 \
      zlib1g-dev=1:1.2.11.dfsg-1 \
      libfreetype6=2.9.1-3+deb10u2 \
      libxrender1=1:0.9.10-1 \
      libxext6=2:1.3.3-1+b2 \
      libx11-6=2:1.6.7-1+deb10u1 \
      libssl-dev=1.1.1d-0+deb10u4 \
      apt-transport-https=1.8.2.2 \
  # install wkhtmltopdf from source to convert html to pdf
  ; curl -L -o wkhtmltopdf.tar.xz https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox-${WKHTMLTOPDF_VERSION}_linux-generic-amd64.tar.xz \
  ; tar -xf wkhtmltopdf.tar.xz \
  ; mv wkhtmltox/bin/wkhtmltopdf /usr/local/bin/wkhtmltopdf \
  ; chmod +x /usr/local/bin/wkhtmltopdf \
  ; wkhtmltopdf -V \
  # install pinned nodejs (from https://github.com/nodejs/docker-node/blob/master/8/jessie/Dockerfile)
  ; ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64';; \
    ppc64el) ARCH='ppc64le';; \
    s390x) ARCH='s390x';; \
    arm64) ARCH='arm64';; \
    armhf) ARCH='armv7l';; \
    i386) ARCH='x86';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  # gpg keys listed at https://github.com/nodejs/node#release-keys
  && set -ex \
  && for key in \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
    B9E2F5981AA6E0CD28160D9FF13993A75599653C \
  ; do \
    gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
# install yarn from source to build JS front-end distribution (from https://github.com/nodejs/docker-node/blob/master/8/jessie/Dockerfile)
  ; set -ex \
  && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
    gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/${YARN_VERSION}/yarn-v${YARN_VERSION}.tar.gz" \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/${YARN_VERSION}/yarn-v${YARN_VERSION}.tar.gz.asc" \
  && gpg --batch --verify yarn-v${YARN_VERSION}.tar.gz.asc yarn-v${YARN_VERSION}.tar.gz \
  && mkdir -p /opt \
  && tar -xzf yarn-v${YARN_VERSION}.tar.gz -C /opt/ \
  && ln -s /opt/yarn-v${YARN_VERSION}/bin/yarn /usr/local/bin/yarn \
  && ln -s /opt/yarn-v${YARN_VERSION}/bin/yarnpkg /usr/local/bin/yarnpkg \
  && rm yarn-v${YARN_VERSION}.tar.gz.asc yarn-v${YARN_VERSION}.tar.gz \
# install phantomjs for pdf generation
  ; curl -L -o phantomjs.tar.bz2 https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-${PHANTOMJS_VERSION}.tar.bz2 \
  ; tar xvjf phantomjs.tar.bz2 \
  ; mv phantomjs-${PHANTOMJS_VERSION}/bin/phantomjs /usr/local/bin/phantomjs \
  ; chmod +x /usr/local/bin/phantomjs \
  ; sed -i '/ssl_conf/s/^/#/g' /etc/ssl/openssl.cnf \
  ; phantomjs -v \
# install PHP composer to install PHP back-end vendors
  ; curl -sS https://getcomposer.org/installer | php -- --filename=composer --install-dir=/usr/local/bin --version=${COMPOSER_VERSION} \
# install APCu Object Cache Backend PHP extension
  ; pear config-set php_ini /usr/local/etc/php/php.ini  && \
    pecl config-set php_ini /usr/local/etc/php/php.ini   && \
    pecl install apcu-${PECL_VERSION} \
# install other PHP extensions
# install pdo_mysql to connect to MySQL database
# install zip dependency for PHPExcel vendor
  ; docker-php-ext-install \
      pdo_mysql \
      zip \
# configure apache2 and inject ip for SERVER_NAME directive
  ; sed -i -e "s/"example.com.br"/`awk 'END{print $1}' /etc/hosts`/g" /etc/apache2/apache2.conf \
  ; sed -i -e "s/#ServerName www.example.com/ServerName `awk 'END{print $1}' /etc/hosts`/g" /etc/apache2/sites-available/000-default.conf \
  ; sed -i -e "s/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www\/html\/public/g" /etc/apache2/sites-available/000-default.conf \
  ; a2enmod rewrite     && \
    a2enmod expires     && \
    a2enmod mime        && \
    a2enmod filter      && \
    a2enmod deflate     && \
    a2enmod proxy_http  && \
    a2enmod headers     && \
    a2enmod php7        \
# change folders ownerships
  ; mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html && \
    chown -R www-data:www-data /var/www && \
    chown -R www-data:www-data /var/log/apache2/ && \
    rm -Rvf /var/www/html/*

# change working directory to /var/www/html
WORKDIR /var/www/html

# creating Laravel with composer and change folder ownerships
RUN composer create-project --prefer-dist laravel/laravel ./ "5.8.*" \ 
  ; chown -R www-data:www-data /var/www/html

# switch to www-data user
USER www-data

# install JS front-end packages using yarn
RUN yarn

# switch to root user
USER root
