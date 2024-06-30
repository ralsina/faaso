# FaaSO

FaaSO is a simple, small, fast, efficient way to deploy your code, written
in pretty much any language, into your own infrastructure.

Or at least that's the plan, although it's not all that yet.

## A VERY Important Note Or Two

Do **NOT** try this unless you are very familiar with Docker, security, programming,
and maybe a dozen other things. This is **NOT** safe to run. You will be giving
alpha-level software access to your Docker, which means it could do horrible,
horrible things to all your containers and, to be honest, your whole system
as well as *maybe* other systems around you.

It tries **NOT** to do that, but hey, I may not be perfect, you know.

Hell, as of this writing the password is hardcoded as "admin/admin", folks.

OTOH, FaaSO aims to be very, **very** clear and obvious on what it does. It's
mostly a very opinionated frontend for docker.

So, when you build a funko (it's explained below) you are building a docker image.
When you run one? You are running a docker container.

You can *always* do anything manually. You can create a funko without using the
FaaSO runtimes. You can instantiate any docker image as a funko. You can export
your funko as a totally standalone containerized app.

## The Name

FaaSO means Functions as a Service Omething. The meaning of the O is still
not decided, I'll figure something out.

## Building

Assuming you have a working [Crystal](https://crystal-lang.org) setup, a
working docker command and a checkout of the source code for FaaSO you can
install it:

Build the binaries and docker image: `make proxy`

This will give you:

* `bin/faaso` the CLI for faaso
* A docker image called `faaso-proxy` which is the "server" component.

## Usage

You need a server, with docker. In that server, build it as explained above.
You can run the `faaso-proxy` with something like this:

```
docker run --network=faaso-net -v /var/run/docker.sock:/var/run/docker.sock -p 8888:8888 faaso-proxy
```

That will give `faaso-proxy` access to your docker, and expose the functionality in
port 8888.

## What it Does

### Funkos

In FaaSO you (the user) can create Funkos. Funkos are the moral equivalent of AWS 
lambdas and whatever they are called in other systems. In short, they are simple
programs that handle web requests.

For example, here is a `hello world` level funko written using Crystal, a file called `funko.cr`:

```crystal
get "/" do
  "Hello World Crystal!"
end
```

Because FaaSO needs some more information about your funko to know how to use it,
you also need a metadata file `funko.yml` in the same folder:

```yml
name: hello
runtime: crystal
```

If you have those two files in a folder, that folder is a funko, which is called
`hello` and FaaSO knows it's written in Crystal. In fact, it knows (because the crystal runtime explains that, don't worry about it yet) that it's part of an
application written in the [Kemal framework](https://kemalcr.com/) and it knows
how to create a whole container which runs the app, and how to check its health,
and so on.

But the funko has *the interesting bits* of the app.

The full details of how to write funkos are still in flux, so not documenting 
it for now. Eventually, you will be able to just write the parts you 
need to write to create funkos in different languages. It's easy!

### So what can a funko do?

Once you have a funko, you can *build* it, which will give you a docker image.

```faaso build --local myfunko/```

Or you can export it and get rid of all the mistery of how your funko **really** works:

```faaso export myfunko```

Or, once you built it, you can run it, and you will be able to see it using 
`docker ps`:

```faaso up myfunko```

### The FaaSO proxy

The proxy has a few goals:

1) You can connect to it using `faaso` and have it build/run/etc your funkos.

   * This builds the funko in your machine: `faaso build -l myfunko/`
   * This builds the funko in the server pointed at by FAASO_SERVER: `faaso build myfunko/`

   Yes, they are exactly the same thing. In fact, if you don't use the `-l` flag,
   faaso just tells the proxy "hey proxy, run *your* copy of faaso over there and
   build this funko I am uploading"

2) It automatically reverse-proxies to all funkos.

   If you deployed a funko called `hello` and your faaso proxy is at
   `http://myserver:8888` then the `/` path in your funko is at 
   `http://myserver:8888/funko/hello/`

   This proxying is automatic, you don't need to do anything. As long as you 
   build the image for your funko in the server and then start the funko in the
   server? It should work.

3) It provides an administrative interface.

   This is still very early days, and is not usable by normal people.

## Contributing

Until FaaSO is in somewhat better shape, I don't want external contributions
beyond bugfixes, since I am redesigning things all the time.

## Contributors

- [Roberto Alsina](https://github.com/ralsina) - creator and maintainer
