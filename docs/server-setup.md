# Setting up a FaaSO Server

This guide will help you set up a FaaSO server which you can use to
deploy your applications.

<script
  src="https://asciinema.org/a/fwGx1rD9m2TzHPBXzHErarfoq.js"
  id="asciicast-fwGx1rD9m2TzHPBXzHErarfoq"
  async="true"></script>

Since FaaSO is a container-based platform, you will need to have Docker
installed on your server. This document assumes some basic familiarity
with the command line and docker itself.

## Getting the FaaSO Server

You can pull its latest image
[from GitHub](https://github.com/users/ralsina/packages/container/package/faaso):

```bash
docker pull ghcr.io/ralsina/faaso:latest
```

If you are on an ARM64 platform, use `faaso-arm64` instead of `faaso`.

## Running the FaaSO Server

It's a normal docker container, so you can run it like this:

```bash
$ docker network create faaso-net  # All faaso containers want this network
$ docker run -d --name faaso-proxy-fadmin \
        --rm --network=faaso-net \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v ${PWD}/secrets:/home/app/secrets \
        -e FAASO_SECRET_PATH=${PWD}/secrets \
        -v ${PWD}/config:/home/app/config \
        -p 127.0.0.1:8888:8888 ghcr.io/ralsina/faaso
```

Let's break down the command:

* `-d` means the container will run in the background.
* `--name faaso-proxy-fadmin` is the name of the container.
  You can use any name you want.
* `--rm` means the container will be removed when it stops.
* `--network=faaso-net` means the container will be on the `faaso-net` network.
  This is needed because that name is hardcoded in FaaSO and it's how the containers
  find each other.
* `-v /var/run/docker.sock:/var/run/docker.sock` is needed so the
  FaaSO server can start and stop containers.
* `-v ${PWD}/secrets:/home/app/secrets` is where the FaaSO server will put
  secrets and where funkos will look for them.
* `-e FAASO_SECRET_PATH=${PWD}/secrets` is needed so the FaaSO server can setup bind
  mounts for funkos to find the secrets.
* `-v ${PWD}/config:/home/app/config` is where the FaaSO server will get its
  configuration.
* `-p 8888:8888` is the port where the FaaSO server will listen for requests.

What can you change? You can change the port, the secrets and configuration
paths. The rest pretty much has to be as shown.

## Configuring the FaaSO Server

The FaaSO server configuration is in `config/faaso.yaml`. Here is a sample
showing **all the available options with their default values**:

```yaml
password: adminfoo
```

That's it. The only configuration option is the password for the admin interface.
The user is always `admin`.

## Reverse Proxy Configuration

* Caddy reads config from `config/Caddyfile` and this is the default, which
  you can change as needed if you are familiar with it. Usually you won't
  need to change anything, so just copy this into `config/Caddyfile`:

```Caddyfile
{
        http_port 8888
        https_port 8887
        local_certs
}

http://*:8888 http://127.0.0.1:8888 {
        forward_auth /admin/* http://127.0.0.1:3000 {
                uri /auth
                copy_headers {
                        Authorization
                }
        }

        handle_path /admin/terminal/* {
                reverse_proxy /* http://127.0.0.1:7681
        }
        handle_path /admin/* {
                reverse_proxy /* http://127.0.0.1:3000
        }
      header Access-Control-Allow-Origin "*"

      import funkos
}
```

The `import funkos` line is important, because `config/funkos` is where FaaSO
configures the reverse proxy for your applications. That file *must exist*.

You can alternatively run the proxy using docker-compose with the
following `docker-compose.yml` (adapt as needed):

```yaml
version: "3.3"
services:
  faaso:
    container_name: faaso-proxy-fadmin
    networks:
      - faaso-net
    environment:
      - FAASO_SECRET_PATH=${PWD}/secrets
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ${PWD}/secrets:/home/app/secrets
      - ${PWD}/config:/home/app/config
    ports:
      - 8888:8888
    image: faaso
networks:
  faaso-net:
    external: true
```

**Note:** While it's technically possible to run the FaaSO server without
the container, it makes absolutely no sense.
