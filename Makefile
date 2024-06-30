build: shard.yml $(wildcard src/**/*cr)
	shards build
proxy: build
	docker build . -t faaso-proxy --no-cache
start-proxy:
	docker run --network=faaso-net -v /var/run/docker.sock:/var/run/docker.sock -p 8888:8888 faaso-proxy


.PHONY: build proxy-image start-proxy
