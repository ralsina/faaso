build: shard.yml $(wildcard src/**/*cr)
	shards build
proxy-image: build
	docker build . -t faaso-proxy --no-cache
start-proxy:
	docker run --network=faaso-net -v /var/run/docker.sock:/var/run/docker.sock -p 8888:8888 -p 3000:3000 faaso-proxy


.PHONY: build proxy-image start-proxy
