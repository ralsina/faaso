FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine as build
RUN apk add crystal shards yaml-dev openssl-dev zlib-dev libxml2-dev
RUN addgroup -S app && adduser app -S -G app
WORKDIR /home/app
COPY shard.yml ./
RUN mkdir src/
COPY src/* src/
RUN shards install
RUN shards build -d --error-trace
RUN strip bin/faaso-daemon

FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine as ship
RUN apk add tinyproxy multirun openssl zlib yaml pcre2 gc libevent libgcc libxml2

# Unprivileged user
RUN addgroup -S app && adduser app -S -G app
WORKDIR /home/app

COPY tinyproxy.conf ./
COPY --from=build /home/app/bin/faaso-daemon ./

CMD ["/usr/bin/multirun", "./faaso-daemon", "tinyproxy -d -c tinyproxy.conf"]