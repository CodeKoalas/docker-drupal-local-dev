FROM alpine as confd

ENV GOPATH /go

RUN mkdir -p "$GOPATH/src/" "$GOPATH/bin" && chmod -R 777 "$GOPATH" && \
    mkdir -p /go/src/github.com/kelseyhightower/confd

RUN apk --update add unzip curl go bash git libc-dev && \
    ln -s /go/src/github.com/kelseyhightower/confd /app

WORKDIR /app

RUN curl -L https://github.com/kelseyhightower/confd/archive/v0.13.0.zip --output /tmp/confd.zip && \
    unzip -d /tmp/confd /tmp/confd.zip && \
    cp -r /tmp/confd/*/* /app && \
    rm -rf /tmp/confd* && \
    ./build

FROM php:7-fpm-alpine

COPY --from=confd /app/bin/confd /usr/local/bin/confd

RUN apk add --no-cache --virtual .ext-deps \
	libpng-dev \
	libjpeg-turbo-dev \
	freetype-dev \
	libmcrypt-dev \
	libwebp-dev \
	openssl-dev \
	gmp-dev \
	openldap-dev

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include --with-webp-dir=/usr/include

RUN pecl install mongodb && \
	pecl clear-cache

RUN docker-php-ext-install mysqli pdo_mysql opcache mcrypt gmp ldap zip bcmath gd && \
	docker-php-ext-enable mongodb.so && \
	docker-php-source delete
