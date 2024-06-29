# Design for FaaSO

## Introduction

This should explain the high-level plan. Of course once I start
writing the thing it will change, because I am *agile* like that.

So, here it is:

## Function Builder

Take the function code, some ancillary files, and build a docker
image using a template so that it can be executed.

Additionally:

* The image should be runnable with a standard `docker run` command
* A test can be defined to check if the function is working

## Function Runner

Given a description of what functions should be made available at
which endpoints, like

/sum -> sum
/mul -> multiply

It should:

* Start those functions via docker, running in specific ports
* Create a reverse proxy that routes the paths to the correct function
* Start/reload/configure the proxy as needed
* Periodically check the functions are still running

Intentionally: No HA yet, no multiple instances of functions, no
up/downscaling, no multiple versions routed by header.

Specifically: no downscaling to zero. It makes everything MUCH
more complicated.

# Function structure

Example using crystal, but it could be anything. Any function has
an associated runtime, for example "crystal" or "python".

That runtime has a template (see `templates/crystal` for example).

To build the function image, the builder will:

* Create a tmp directory
* Copy the template files to the tmp directory
* Overlay the function files on top of the template
* Build using the template Dockerfile

For docker that implies:

* Use an alpine builder, install crystal, shards, whatever
* Run "shards isntall" to get the dependencies
* Run "shards build" to build the function
* Copy the function binary to ~app

When running, it will just run that binary and map a port to port 3000.

Template metadata:

Probably some `metadata.yml` that is *not* in the template.

* Additional packages to install in the alpine builder
* Files that should be copied along the function
* Whatever

# Implementation Ideas

* caddy for proxy? It's simple, fast, API-configurable.
* Local docker registry for images? See https://www.docker.com/blog/how-to-use-your-own-registry-2/
