FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine as build
RUN apk update && apk add crystal shards yaml-dev openssl-dev zlib-dev libxml2-dev && apk cache clean
RUN addgroup -S app && adduser app -S -G app
WORKDIR /home/app
COPY shard.yml ./
RUN mkdir src/
COPY src/ src/
RUN shards install
RUN shards build -d --error-trace
RUN strip bin/*

FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine as ship
RUN apk update && apk add caddy multirun docker openssl zlib yaml pcre2 gc libevent libgcc libxml2 ttyd && apk cache clean

# Unprivileged user
RUN addgroup -S app && adduser app -S -G app
WORKDIR /home/app

RUN mkdir runtimes public
COPY runtimes/ runtimes/
COPY public/ public/
COPY Caddyfile ./
COPY --from=build /home/app/bin/faaso-daemon /home/app/bin/faaso /usr/bin/

RUN mkdir /secrets

CMD ["/usr/bin/multirun", "-v", "faaso-daemon", "caddy run --config Caddyfile"]
