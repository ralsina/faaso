# FaaSO: Why, What, How

FaaSO is a platform for running serverless functions. It is designed to be
simple to use, and to be able to run on any infrastructure. But in real life
it's mostly meant to be used by self-hosters to run their own code on
their own hardware.

It has been interesting to decide the design constraints for FaaSO. Here are
what I came up with:

* Fast ramp-up. You can go from zero to running code in a few minutes.
* Very simple deployment. Just run a command or two.
* Convention over configuration: FaaSO will make a lot of decisions for you.
* No lock-in. You are free to move *away* from FaaSO. Just export your code
  and run that docker image however you want.
* Single tenant: FaaSO will not protect you from yourself. It assumes everyone
  using it is trusted. This simplifies a lot of things.
* No state: Functions are stateless. If you need state, you need to manage it
  yourself.
* Simple secret support: yes, you can tell a function a secret, but it's not
  meant to be a secure way to do it. Anyone with access to the server can see
  it.
* No real horizontal scaling. If your service is larger than your server, then
  go get a bigger server. This is not AWS Lambda.
* Small. I refuse to let FaaSO grow more than 1500 lines of code. It's at 1200
  now, so I have some room to grow.

Having said all that, let's get to the interesting bits:

## Architecture

FaaSO as a platform has three components:

* A service that manages your code. Because "function" is boring, I call them
  "funkos". This service is called the "faaso proxy service".
* A [CLI](cli.md) client called `faaso` that lets you interact with the proxy service
  and develop funkos locally on your machine.
* A web interface for easy management of running funkos.

The faaso proxy service (the proxy from now on) uses Docker as source of truth.
It literally doesn't save **anything** to disk or to any database, excepto for
some minor temporary files.

What does "docker as source of truth" imply?

* A funko, as fas as the proxy is concerned, is a docker image whose name
  starts with "faaso-". The rest of the name is the funko name. So, a funko
  named "hello" will have an associated docker image named "faaso-hello".
* Funko instances are containers running that image. They have names like
  "faaso-hello-weygf6". So: "faaso-" + funko name + "-" + random string.
* A funko's `scale` is the number of instances of that funko that are running.
* An instance is `out of date` if it's not running the latest known image for
  that funko.
* All funkos run in the `faaso-net` network, so they can talk to each other
  and to the proxy.
* Funkos open port `3000`
* Funkos respond to `/ping` with a `200 OK` if they are OK.

When you use any of the FaaSO tools to manage your funkos, what they do is work
with docker. Building a funko? Builds a docker image. Scaling a funko up or down?
Starts or stops docker containers. And so on.

There is **ZERO MAGIC** here. If you know docker, you know how FaaSO works. If you
want, you can do exactly what FaaSO does using docker commands, and FaaSO won't mind.

In addition to all your funkos, FaaSO will run one container of its own: the `faaso-proxy`.

## The Proxy

The proxy listens on port `8888` and is the only thing that needs to be
exposed to the users / the Internet. It will automatically work as
reverse proxy for all funkos.

* A funko called `hello` will be available at `http://proxy:8888/faaso/hello/`
* A funko can respond to whatever path it wants, if it responds to `/foo/bar`,
  that will be accessible as `http://proxy:8888/faaso/hello/foo/bar`
* The admin interface is at `http://proxy:8888/admin/` and is behind a simple
  password protection.
* The URL for the admin interface is what you should set as `FAASO_SERVER` for
  the CLI.

Internally, the proxy uses [caddy](https://caddyserver.com) as a reverse proxy
and configures it as needed when funkos are started or stopped.

## What else

There is not much more to FaaSO. It's not meant to be a replacement for
AWS Lambda or Google Cloud Functions. It's meant to be a simple way to
run your own code on your own hardware.

Your next steps are probably to [set up a faaso proxy](server-setup.md),
and learn how to [write code to run on it](funko-dev.md).
