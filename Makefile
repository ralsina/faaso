build: shard.yml $(wildcard src/**/*cr)
	shards build
proxy: build
	docker build . -t faaso-proxy
start-proxy:
	docker run --name faaso-proxy-one --rm --network=faaso-net -v /var/run/docker.sock:/var/run/docker.sock -v secrets:/home/app/secrets -p 8888:8888 faaso-proxy


.PHONY: build proxy-image start-proxy
