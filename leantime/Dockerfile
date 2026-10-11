ARG BUILD_FROM=leantime/leantime:latest
FROM ${BUILD_FROM}

USER root

# Install MariaDB server and client, jq, bash, and utilities
RUN apk update && apk add --no-cache \
    mariadb \
    mariadb-client \
    mariadb-server-utils \
    bash \
    jq \
    curl \
    tzdata \
    && rm -rf /var/cache/apk/*

# Copy startup script
COPY run.sh /run.sh
RUN chmod +x /run.sh

WORKDIR /var/www/html

EXPOSE 8080

ENTRYPOINT ["/run.sh"]
