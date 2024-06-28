FROM --platform=${TARGETPLATFORM:-linux/amd64} ghcr.io/openfaas/of-watchdog:0.9.10 as watchdog
FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine as build
ARG ADDITIONAL_PACKAGE

COPY --from=watchdog /fwatchdog /usr/bin/fwatchdog

RUN apk update && apk upgrade && apk add crystal shards openssl-dev ${ADDITIONAL_PACKAGE} && apk cache clean

WORKDIR /home/app

COPY function/shard.yml shard.yml
RUN shards install
COPY . .
RUN crystal build main.cr -o handler --error-trace -p  && rm -rf /root/.cache

FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine as ship
ARG ADDITIONAL_PACKAGE
RUN apk update && apk upgrade && apk add openssl pcre2 libgcc gc libevent ${ADDITIONAL_PACKAGE} && apk cache clean
# Add non root user
# Add non root user
RUN addgroup -S app && adduser app -S -G app

WORKDIR /home/app
USER app

COPY --from=build /home/app/function/  .
COPY --from=build /home/app/handler    .
COPY --from=watchdog /fwatchdog /usr/bin/fwatchdog

ENV fprocess="./handler"
ENV exec_timeout=30
EXPOSE 8080

HEALTHCHECK --interval=2s CMD [ -e /tmp/.lock ] || exit 1

ENV upstream_url="http://127.0.0.1:5000"
ENV mode="http"

CMD ["fwatchdog"]
