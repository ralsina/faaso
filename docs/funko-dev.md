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

## Prerequisites

* Setup a [FaaSO server](server-setup.md)
* Get the [Faaso CLI](cli.md)

## Getting Started

Assuming you have a working FaaSO environment, we need to create a new
funko, let's call it `historico` and you can create it based on any of the
available runtimes which you can see running `faaso new -r list`

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

Where is the code that is *doing* that? It depends on the runtime, but
usually it's called "funko" with the extension for the language of the
runtime. In this case, it's `funko.cr`:

```crystal
require "kemal"

# This is a kemal app, you can add handlers, middleware, etc.

# A basic hello world get endpoint
get "/" do
  "Hello World Crystal!"
end

# The `/ping/` endpoint is configured in the container as a healthcheck
# You can make it better by checking that your database is responding
# or whatever checks you think are important
#
get "/ping/" do
  "OK"
end
```

Now, that's not really a very interesting app. Let's make it do what we want
it to do. What I want is to run this query against my PostgreSQL database and
return the results as JSON:

```sql
SELECT year::integer, counter::integer
  FROM names WHERE name = '#{nombre}'
ORDER BY year
```

Of course that involves a series of things:

* Have a PostgreSQL database with the data
* A user/password to connect to it
* Install the PostgreSQL client library for Crystal
* Get the name/names I want data on as a parameter
* Writing the code to connect to the database and run the query
* Formatting the output as JSON and returning it

If you **really** want to see this in action for yourself on your hardware,
you can make this database accessible to your funko by running this command
*in the same machine where you have the FaaSO server running*:

```bash
$ docker run -ti --rm -p 5432:5432 \
  --network faaso-net --name database \
  ghcr.io/ralsina/postgres-nombres:latest

[ ... lots of output, takes a minute or five ... ]

LOG:  database system is ready to accept connections
```

Since we now have a database, let's get the Crystal client library for
PostgreSQL. In Crystal, you add dependencies to a `shard.yml` file,
and your funko has one. Here, I added the `pg` shard:

```yaml
name: historico
version: 0.1.0

targets:
  funko:
    main: main.cr

dependencies:
  kemal:
    github: kemalcr/kemal
  pg:
    github: will/crystal-pg
```

What about the user/password for the database? Well, those are *secrets*.

FaaSO has a very basic secrets management system. You can add secrets
using the CLI and they are available to the funkos on runtime.

**FIXME RELEASE BLOCKER** input of secrets unless via pipe is pretty broken.

```bash
$ faaso secret -a historico pass
Enter the secret, end with Ctrl-D
[...]
Secret created

faaso/historico on  main [!?] is 📦 v0.1.0 via 🔮 v1.13.0 took 2s
> faaso secret -a historico user
Enter the secret, end with Ctrl-D
[...]
Secret created
```

To access those secrets, the funko should read '/secrets/secretname' (in this
case, `/secrets/user` and `/secrets/pass`).

The code to connect to the database and run the query is pretty simple
but beyond the scope of this tutorial:

```crystal
require "json"
require "kemal"
require "pg"

# get credentials from secrets

USER = File.read("/secrets/user").strip
PASS = File.read("/secrets/pass").strip

# Connect to the database and get information about
# the requested names
get "/" do |env|
  # Names are query parameters
  names = env.params.query["names"].split(",")
  # Connect using credentials provided

  results = {} of String => Array({Int32, Int32})
  DB.open("postgres://#{USER}:#{PASS}@database:5432/nombres") do |cursor|
    # Get the information for each name
    names.map do |name|
      results[name] = Array({Int32, Int32}).new
      cursor.query("
      SELECT anio::integer, contador::integer
        FROM nombres WHERE nombre = $1
      ORDER BY anio", name) do |result_set|
        result_set.each do
          results[name] << {result_set.read(Int32), result_set.read(Int32)}
        end
      end
    end
  end
  results.to_json
end

```

After updating the code we have to rebuild the funko and deploy it again:

```bash
$ faaso build .

[ ... Lots of output]

$ faaso status historico
2024-07-14T19:31:40.321545Z   INFO - Name: historico
2024-07-14T19:31:40.321553Z   INFO - Scale: 1
2024-07-14T19:31:40.324341Z   INFO - Containers: 1
2024-07-14T19:31:40.324352Z   INFO -   /faaso-historico-D2YfXw Up
  11 minutes (healthy) (Out of date)
2024-07-14T19:31:40.324358Z   INFO - Images: 1
2024-07-14T19:31:40.324387Z   INFO -   ["faaso-historico:latest"]

$ faaso deploy historico
Deploying historico
Need to update 1 containers
Scaling from 1 to 2
Scaling historico from 1 to 2
Adding instance
Waiting for 2 containers to be healthy
Funko historico has 1/2 healthy containers
[ ... repeated ... ]
Funko historico has 2/2 healthy containers
Funko historico reached scale 2
Scaling down to 1
Scaling historico from 2 to 1
Removing instance
Funko historico has 2/2 healthy containers
Funko historico has 2/1 running containers
Funko historico reached scale 1
Deployed historico
```

The new `faaso deploy` command looks for instances of the funko running old code
and replaces them with new instances running the latest and greatest. So now we
should be able to use it!

```bash
$ curl 'http://localhost:8888/faaso/historico/?names=juan,pedro' | jq . | head -10
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  2335  100  2335    0     0   144k      0 --:--:-- --:--:-- --:--:--  152k
{
  "juan": [
    [
      1922,
      403
    ],
    [
      1923,
      612
    ],

[... lots more output]
```

And that's it! You have a funko that connects to a database, gets data, and
creates a response. This can be combined with a static frontend to display
the data in a nice chart. You can see it working in **TODO** add URL.
