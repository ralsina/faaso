FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine:3.20 AS build
RUN apk add --no-cache \
    crystal \
    shards \
    yaml-dev \
    openssl-dev \
    zlib-dev \
    libxml2-dev \
    make
RUN rm -rf /var/cache/apk/*
RUN addgroup -S app && adduser app -S -G app
WORKDIR /home/app
COPY shard.yml Makefile ./
RUN mkdir src/
COPY src/ src/
COPY runtimes/ runtimes/
RUN make
# RUN strip bin/*

FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine:3.20 AS ship
RUN apk add --no-cache \
    caddy \
    nss-tools \
    multirun \
    docker \
    openssl \
    zlib \
    yaml \
    pcre2 \
    gc \
    libevent \
    libgcc \
    libxml2 \
    ttyd
RUN rm -rf /var/cache/apk/*

# Unprivileged user
RUN addgroup -S app && adduser app -S -G app
WORKDIR /home/app
RUN mkdir /home/app/tmp && chown app /home/app/tmp

COPY public/ public/
COPY --from=build /home/app/bin/faaso-daemon /home/app/bin/faaso /usr/bin/

# Mount points for persistent data
RUN mkdir /secrets /config

CMD ["/usr/bin/multirun", "-v", "faaso-daemon", "caddy run --config config/Caddyfile"]
