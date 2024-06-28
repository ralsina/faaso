FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine as build

RUN apk update && apk upgrade && apk add crystal shards openssl-dev zlib-dev && apk cache clean

WORKDIR /home/app

COPY shard.yml *.cr .
RUN shards install
RUN shards build

FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine as ship
RUN apk update && apk upgrade && apk add openssl pcre2 libgcc gc libevent && apk cache clean
RUN addgroup -S app && adduser app -S -G app

WORKDIR /home/app
USER app

COPY --from=build /home/app/bin/function  .

CMD ["./function"]
