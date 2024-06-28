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

# Implementation Ideas

* caddy for proxy? It's simple, fast, API-configurable.
* Local docker registry for images? See https://www.docker.com/blog/how-to-use-your-own-registry-2/
* Maybe grip for crystal template? Maybe kemal?
