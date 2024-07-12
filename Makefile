build: shard.yml $(wildcard src/**/*) $(runtimes/**/*)
	shards build -d --error-trace -Dstrict_multi_assign -Dno_number_autocast
	cat .rucksack >> bin/faaso
	cat .rucksack >> bin/faaso-daemon
proxy:
	docker build . -t faaso-proxy

all: build proxy

start-proxy:
	docker network create faaso-net || true
	docker run --name faaso-proxy-fadmin \
	--rm --network=faaso-net \
	-e FAASO_SECRET_PATH=${PWD}/secrets \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-v ${PWD}/secrets:/home/app/secrets \
	-v ${PWD}/config:/home/app/config \
	-p 8888:8888 faaso-proxy

test:
	crystal spec

clean:
	rm bin/*

static:
	shards build faaso --static --release --no-debug -Dstrict_multi_assign -Dno_number_autocast
	cat .rucksack >> bin/faaso
	strip bin/faaso

.PHONY: all build proxy-image start-proxy test clean static
