# base image for PHP version 7.2
FROM php:7.2-apache
LABEL maintainer="PremiaLab"
LABEL author="Bryan Vaz"
USER root

# environment variables
ENV DEBIAN_FRONTEND noninteractive
ENV PHANTOMJS_VERSION 2.1.1-linux-x86_64
ENV NODE_VERSION 8.15.0
ENV YARN_VERSION 1.13.0
ENV COMPOSER_VERSION 1.8.0
ENV PECL_VERSION 5.1.16
# install wkhtmltopdf 0.12.3 because the quality is better than 0.12.4
ENV WKHTMLTOPDF_VERSION 0.12.3

# Node User
RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

# install all the system dependencies
# install apt-utils for workaround of missing ubuntu package
# install gpg to install nodejs and yarn from source
# install zip and unzip to install composer vendors
# install git to install dependencies from git repositories
# install wkhtmltopdf dependencies to convert html to pdf
RUN apt-get update && apt-get install -y \
  apt-utils=1.4.8 \
  gnupg=2.1.18-8~deb9u3 \
  zip=3.0-11+b1 \
  unzip=6.0-21 \
  git=1:2.11.0-3+deb9u4 \
  libfontconfig1=2.11.0-6.7+b1 \
  zlib1g-dev=1:1.2.8.dfsg-5 \
  libfreetype6=2.6.3-3.2 \
  libxrender1=1:0.9.10-1 \
  libxext6=2:1.3.3-1+b2 \
  libx11-6=2:1.6.4-3+deb9u1 \
  libssl1.0-dev=1.0.2q-1~deb9u1 \
  apt-transport-https=1.4.8

# install wkhtmltopdf from source to convert html to pdf
RUN curl -L -o wkhtmltopdf.tar.xz https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox-${WKHTMLTOPDF_VERSION}_linux-generic-amd64.tar.xz \
  ; tar -xf wkhtmltopdf.tar.xz \
  ; mv wkhtmltox/bin/wkhtmltopdf /usr/local/bin/wkhtmltopdf \
  ; chmod +x /usr/local/bin/wkhtmltopdf \
  ; wkhtmltopdf -V

# install pinned nodejs (from https://github.com/nodejs/docker-node/blob/master/8/jessie/Dockerfile)
RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
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
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs


# install yarn from source to build JS front-end distribution (from https://github.com/nodejs/docker-node/blob/master/8/jessie/Dockerfile)
RUN set -ex \
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
  && rm yarn-v${YARN_VERSION}.tar.gz.asc yarn-v${YARN_VERSION}.tar.gz

# install phantomjs for pdf generation
RUN curl -L -o phantomjs.tar.bz2 https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-${PHANTOMJS_VERSION}.tar.bz2 \
  ; tar xvjf phantomjs.tar.bz2 \
  ; mv phantomjs-${PHANTOMJS_VERSION}/bin/phantomjs /usr/local/bin/phantomjs \
  ; chmod +x /usr/local/bin/phantomjs \
  ; phantomjs -v

# install PHP composer to install PHP back-end vendors
RUN curl -sS https://getcomposer.org/installer | php -- --filename=composer --install-dir=/usr/local/bin --version=${COMPOSER_VERSION}

# install APCu Object Cache Backend PHP extension
RUN pear config-set php_ini /usr/local/etc/php/php.ini  && \
    pecl config-set php_ini /usr/local/etc/php/php.ini   && \
    pecl install apcu-${PECL_VERSION}

# install other PHP extensions
# install pdo_mysql to connect to MySQL database
# install zip dependency for PHPExcel vendor
RUN docker-php-ext-install \
  pdo_mysql \
  zip

# configure apache2
RUN a2enmod rewrite     && \
    a2enmod expires     && \
    a2enmod mime        && \
    a2enmod filter      && \
    a2enmod deflate     && \
    a2enmod proxy_http  && \
    a2enmod headers     && \
    a2enmod php7

# change folders ownerships
RUN chown -R www-data:www-data /var/www && \
    chown -R www-data:www-data /var/log/apache2/ && \
    rm -Rvf /var/www/html/*

# change working directory to /var/www/html
WORKDIR /var/www/html

# switch to www-data user
USER www-data

# install JS front-end packages using yarn
ADD package.json /tmp/package.json
RUN cd /tmp && yarn
RUN mkdir -p /var/www/html && cd /var/www/html && rm -rf node_modules && ln -sf /tmp/node_modules

# install PHP back-end vendors using composer
# https://getcomposer.org/doc/faqs/how-to-install-untrusted-packages-safely.md
# https://adamcod.es/2013/03/07/composer-install-vs-composer-update.html
ADD composer.json composer.json
RUN mkdir database \
  ; composer install

# switch to root user
USER root