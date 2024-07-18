# FaaSO

FaaSO is a simple, small, fast, efficient way to deploy your code, written
in pretty much any language, into your own infrastructure.

Or at least that's the plan, although it's not all that yet.

## A VERY Important Note Or Two

Do **NOT** try this ,*yet* unless you are familiar with Docker, security, programming,
and maybe a dozen other things. This is **NOT** safe to run. You will be giving
alpha-level software access to your Docker, which means it could do horrible,
horrible things to all your containers and, to be honest, your whole system
as well as *maybe* other systems around you.

It tries **NOT** to do that, but hey, I may not be perfect, you know.

## Building

Assuming you have a working [Crystal](https://crystal-lang.org) setup, a
working docker command and a checkout of the source code for FaaSO you can
install it:

Build the binaries and docker image: `make build proxy`

This will give you:

* `bin/faaso` the CLI for faaso
* A docker image called `faaso-proxy` which is the "server" component.

Further and more current information is/will be available at
[the website.](https://faaso.ralsina.me)

## Contributing

Until FaaSO is in somewhat better shape, I don't want external contributions
beyond bugfixes, since I am redesigning things all the time.

## Contributors

* [Roberto Alsina](https://github.com/ralsina) - creator and maintainer
