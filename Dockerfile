FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine as build
RUN apk update && apk add crystal shards yaml-dev openssl-dev zlib-dev libxml2-dev make && apk cache clean
RUN addgroup -S app && adduser app -S -G app
WORKDIR /home/app
COPY shard.yml Makefile ./
RUN mkdir src/
COPY src/ src/
COPY runtimes/ runtimes/
RUN make
# RUN strip bin/*

FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine as ship
RUN apk update && apk add caddy nss-tools multirun docker openssl zlib yaml pcre2 gc libevent libgcc libxml2 ttyd && apk cache clean

# Unprivileged user
RUN addgroup -S app && adduser app -S -G app
WORKDIR /home/app
RUN mkdir /home/app/tmp && chown app /home/app/tmp

COPY public/ public/
COPY --from=build /home/app/bin/faaso-daemon /home/app/bin/faaso /usr/bin/

# Mount points for persistent data
RUN mkdir /secrets
RUN mkdir /config

CMD ["/usr/bin/multirun", "-v", "faaso-daemon", "caddy run --config config/Caddyfile"]
