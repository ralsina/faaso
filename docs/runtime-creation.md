# Runtime Creation

Runtimes are a core concept in FaaSO. They contain all the bits
that are missing from a Funko to turn it into a complete
application, and thus are the thing that gives a Funko
its illusion of simplicity.

## What is a runtime

* A folder.
* With files.
* With a `template` subfolder.
* Which combined with a Funko produces a container.

Let's look at the `flask` runtime as an example:

```
> tree flask
flask
├── Dockerfile.j2
├── main.py
├── README.md
└── template
    ├── funko.py.j2
    ├── funko.yml.j2
    ├── public
    │   └── index.html
    └── requirements.txt
```

All the files with `.j2` extension are Jinja2 templates (actually [Crinja](https://straight-shoota.github.io/crinja/)).

## The `template` Folder

When the user says `faaso new -r flask myapp`, faaso:

* Creates a new folder `myapp`.
* Copies the contents of `flask/template` into `myapp`.
* All files that are `.j2` are rendered with `{{name}}`
  replaced with `myapp`.

## How are runtimes used

When the user says `faaso build myapp`, faaso:

* Creates a temporary folder.
* Copies the contents of the runtime into the temporary folder.
* Files with `.j2` extension are rendered using
  `myapp/funko.yml` as context.

For example, a `funko.yml` might look like this:

```yaml
name: historico
runtime: kemal
options:
  shard_build_options: ""
  ship_packages: ["curl", "fish"]
  devel_packages: []
  healthcheck_options: "--interval=1m --timeout=2s --start-period=2s --retries=3"
  healthcheck_command: "curl --fail http://localhost:3000/ping || exit 1"
```

And a `Dockerfile.j2` has this sort of content:

```Dockerfile
ARG BUILDPLATFORM
FROM --platform=${BUILDPLATFORM:-foobar} alpine AS build
RUN apk add --no-cache \
    crystal \
    shards \
    openssl-dev \
    zlib-dev {{ options.ship_packages | join(" ") }} {{ options.devel_packages | join(" ") }}
```

So, after it's rendered, the `Dockerfile` will look like this:

```Dockerfile
ARG BUILDPLATFORM
FROM --platform=${BUILDPLATFORM:-foobar} alpine AS build
RUN apk add --no-cache \
    crystal \
    shards \
    openssl-dev \
    zlib-dev curl fish
```

## How to create a new runtime

Create a basic application using the language and framework
of your choise. Add a `Dockerfile` such that it builds the
app and runs it in port `3000`

Then, for each file, decide whether the user needs to care
for it or not. If the user should care, put it in `template`

Then, for each file, rename as `filename.j2` and replace the
parts that should be configured with jinja expressions to
generate them.

Finally, create:

* `README.md` describing the thing. Put a descriptive
  title in the 1st line.
* `template/funko.yml.j2` with the default configuration
  for a funko using your runtime.

For example, in the kemal runtime, the `funko.yml.j2` looks like this:

```yaml
name: {{ name }}
runtime: {{ runtime }}
options:
  shard_build_options: "--release"
  ship_packages: []
  devel_packages: []
  healthcheck_options: "--interval=1m --timeout=2s --start-period=2s --retries=3"
  healthcheck_command: "curl --fail http://localhost:3000/ping || exit 1"
```

And that's it. You can now create funkos using your runtime.

If you think it would be useful for others, feel free to create a PR adding it to the `runtimes` folder in the main repository.
