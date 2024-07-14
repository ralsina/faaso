# Writing your First Funko for FaaSO

This is a tutorial showing how to develop your own application
for FaaSO. It's not a *large* application, but it uses most
of the capabilities of the platform.

## The Application

It's called "historico" and it creates data for a chart showing
the historic popularity of one or more names in Argentina.
It uses a database with names and information you can get from the
Argentine government, which I have cleaned up and made available
in a convenient format [in DoltHub](https://www.dolthub.com/repositories/ralsina/nombres_argentina_1922_2005/doc/main)

**TODO:** provide a dummy version of the data so user can follow along

## Prerequisited

* Setup a [FaaSO server](server-setup.md)
* Get the [Faaso CLI](cli.md)

## Getting Started

Assuming you have a working FaaSO environment, we need to create a new
funko, let's call it `historico` and you can create it based on any of the
available runtimes which you can see running `faaso new -r list`

**TODO:** improve runtimes CLI, make it possible to see descriptions for runtimes

```bash
$ faaso new -r list

FaaSO has some included runtimes:

  * express       - # NodeJS and the Express framework <https://expressjs.com>
  * flask         - # Python and the Flask framework <https://flask.palletsprojects.com/>
  * kemal         - # Crystal with the Kemal framework <https://kemalcr.com>

Or if you have your own, use a folder name
```

So, let's create a new funko using one of the runtimes:

```bash
$ faaso new -r kemal historico
Using known runtime kemal
  Creating file historico/funko.yml from runtimes/kemal/template/funko.yml.j2
  Creating file historico/shard.yml from runtimes/kemal/template/shard.yml.j2
  Creating file historico/README.md from runtimes/kemal/template/README.md.j2
  Creating file historico/funko.cr from runtimes/kemal/template/funko.cr
```

Now you have a new folder called `historico` with the basic structure of a
funko ready for editing. We can actually just deploy it now, to verify our
whole setup works.

```text
$ cd historico

$ faaso login

Enter password for <http://localhost:8888/admin/>
[...]

$ faaso build .

Using known runtime kemal
  Creating file /tmp/MrxYcBg8/README.md from runtimes/kemal/README.md
  Creating file /tmp/MrxYcBg8/main.cr from runtimes/kemal/main.cr
  Creating file /tmp/MrxYcBg8/Dockerfile from runtimes/kemal/Dockerfile.j2
Uploading funko to http://localhost:8888/admin/
Starting remote build:
2024-07-14T16:31:19.704782Z   INFO - Building function... historico in /tmp/kB1DKuBs
2024-07-14T16:31:19.704791Z   INFO - Building image for historico in /tmp/kB1DKuBs
2024-07-14T16:31:19.704907Z   INFO -    Tags: ["faaso-historico:latest"]
2024-07-14T16:31:19.709836Z   INFO - Step 1/15 : FROM --platform=${...

[Lots and lots of output]

2024-07-14T16:33:24.029035Z   INFO - ---> Removed intermediate container b2ba9c627b0d
2024-07-14T16:33:24.029072Z   INFO - ---> 571c4ef56efc
2024-07-14T16:33:24.029346Z   INFO - Successfully built 571c4ef56efc
2024-07-14T16:33:24.038916Z   INFO - Successfully tagged faaso-historico:latest
Build finished successfully.
```

This has built the docker image for our funko, but that doesn't mean it's running:

```bash
$ faaso status historico
2024-07-14T16:34:33.228869Z   INFO - Name: historico
2024-07-14T16:34:33.228880Z   INFO - Scale: 0
2024-07-14T16:34:33.228885Z   INFO - Containers: 0
2024-07-14T16:34:33.228890Z   INFO - Images: 1
2024-07-14T16:34:33.228925Z   INFO -   ["faaso-historico:latest"]
```

To actually run it, we need to scale it to at least 1:

```bash
$ faaso scale historico 1
2024-07-14T16:35:17.120410Z   INFO - Scaling historico from 0 to 1
2024-07-14T16:35:17.120418Z   INFO - Adding instance

$ faaso status historico
2024-07-14T16:35:33.947796Z   INFO - Name: historico
2024-07-14T16:35:33.947806Z   INFO - Scale: 1
2024-07-14T16:35:33.947810Z   INFO - Containers: 1
2024-07-14T16:35:33.947816Z   INFO -   /faaso-historico-46AE5d Up 16 seconds (healthy)
2024-07-14T16:35:33.947821Z   INFO - Images: 1
2024-07-14T16:35:33.947862Z   INFO -   ["faaso-historico:latest"]
```

And we can now see if it works. The simplest way is to use `curl`:

```bash
$ curl 'http://localhost:8888/faaso/historico/'
Hello World Crystal!⏎

$ curl 'http://localhost:8888/faaso/historico/ping/'
OK⏎
```

By convention, funkos are always visible in `/faaso/funkoname/` and they
come with a secondary `/ping/` endpoint that should return `OK`.
