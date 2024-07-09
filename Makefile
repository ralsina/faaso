build: shard.yml $(wildcard src/**/*) $(runtimes/**/*)
	shards build -d --error-trace
	cat .rucksack >> bin/faaso
	cat .rucksack >> bin/faaso-daemon
proxy:
	docker build . -t faaso-proxy

all: build proxy

start-proxy:
	docker run --name faaso-proxy-one \
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

.PHONY: all build proxy-image start-proxy test clean
