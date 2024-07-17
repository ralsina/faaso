FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine:3.20 AS build
RUN apk add --no-cache \
    crystal \
    shards \
    yaml-dev \
    openssl-dev \
    zlib-dev \
    libxml2-dev \
    make
RUN addgroup -S app && adduser app -S -G app
WORKDIR /home/app
COPY shard.yml Makefile ./
RUN mkdir src/
COPY src/ src/
COPY runtimes/ runtimes/
RUN make
RUN strip bin/*

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
# Mount points for persistent data
RUN mkdir /secrets /config
COPY config/Caddyfile config/faaso.yml /config/
# Unprivileged user
RUN addgroup -S app && adduser app -S -G app
WORKDIR /home/app
# Run as root because of docker socket permissions for now
# USER app
RUN mkdir /home/app/tmp && chown app /home/app/tmp

COPY public/ public/
COPY config/ config/
RUN touch config/funkos

COPY --from=build /home/app/bin/faaso-daemon /home/app/bin/faaso /usr/bin/

CMD ["/usr/bin/multirun", "-v", "faaso-daemon", "caddy run --config config/Caddyfile"]
