{{% tag div class="python" %}}
# Writing your First Funko for FaaSO using Python and Flask
{{% /tag %}}
{{% tag div class="crystal" %}}
# Writing your First Funko for FaaSO using Crystal and Kemal
{{% /tag %}}
{{% tag div class="nodejs" %}}
# Writing your First Funko for FaaSO using NodeJS and Express
{{% /tag %}}

This is a tutorial showing how to develop your own application
for FaaSO. It's not a *large* application, but it uses many
of the platform's capabilities.

Choose your language:

<span
  id="crystal-button"
  class="outline"
  role=button
  onCLick="switchTo('crystal');">Crystal
</span>
<span
  id="python-button"
  role=button
  onCLick="switchTo('python');">Python
</span>
<span
  id="nodejs-button"
  role=button
  onCLick="switchTo('nodejs');">NodeJS
</span>

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

```text
$ faaso new -r list

FaaSO has some included runtimes:

  * express       - # NodeJS and the Express framework <https://expressjs.com>
  * flask         - # Python and the Flask framework <https://flask.palletsprojects.com/>
  * kemal         - # Crystal with the Kemal framework <https://kemalcr.com>

Or if you have your own, use a folder name
```

So, let's create a new funko using one of the runtimes:

{{% tag div class="crystal" %}}
```text
$ faaso new -r kemal historico
Using known runtime kemal
  Creating file historico/funko.yml from runtimes/kemal/template/funko.yml.j2
  Creating file historico/shard.yml from runtimes/kemal/template/shard.yml.j2
  Creating file historico/README.md from runtimes/kemal/template/README.md.j2
  Creating file historico/funko.cr from runtimes/kemal/template/funko.cr
```
{{% /tag %}}

{{% tag div class="python" %}}
```text
$ faaso new -r flask historico
Using known runtime flask
  Creating file historico/requirements.txt from runtimes/flask/template/requirements.txt
  Creating file historico/funko.py from runtimes/flask/template/funko.py.j2
  Creating file historico/public/index.html from runtimes/flask/template/public/index.html
  Creating file historico/funko.yml from runtimes/flask/template/funko.yml.j2
```
{{% /tag %}}

Now you have a new folder called `historico` with the basic structure of a
funko ready for editing. We can actually just deploy it now, to verify our
whole setup works.

```text
$ cd historico

$ faaso login

Enter password for <http://localhost:8888/admin/>
[...]

```

{{% tag div class="crystal" %}}
```text
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
{{% /tag %}}

{{% tag div class="python" %}}
```text
$ faaso build .
Using known runtime flask
  Creating file /tmp/EFJBXt12/main.py from runtimes/flask/main.py
  Creating file /tmp/EFJBXt12/README.md from runtimes/flask/README.md
  Creating file /tmp/EFJBXt12/Dockerfile from runtimes/flask/Dockerfile.j2
Using server http://localhost:8888/admin/
Uploading funko to http://localhost:8888/admin/
Starting remote build:
2024-07-22T18:39:51.055912Z   INFO - Building function... historico in /tmp/P2aA1vX5
2024-07-22T18:39:51.055917Z   INFO - Building image for historico in /tmp/P2aA1vX5
2024-07-22T18:39:51.055973Z   INFO -    Tags: ["faaso-historico:latest", "faaso-historico:1721673591"]
2024-07-22T18:39:51.059349Z   INFO - Step 1/17 : ARG BUILDPLATFORM

[Lots and lots of output]

2024-07-22T18:42:40.054931Z   INFO - ---> Running in a7dec4123e2b
2024-07-22T18:42:41.023699Z   INFO - ---> Removed intermediate container a7dec4123e2b
2024-07-22T18:42:41.023722Z   INFO - ---> 1b58e426121e
2024-07-22T18:42:41.024123Z   INFO - Successfully built 1b58e426121e
2024-07-22T18:42:41.034989Z   INFO - Successfully tagged faaso-historico:latest
2024-07-22T18:42:41.041069Z   INFO - Successfully tagged faaso-historico:1721673718
Build finished successfully.
```
{{% /tag %}}

This has built the docker image for our funko, but that doesn't mean it's running:

```text
$ faaso status historico
2024-07-14T16:34:33.228869Z   INFO - Name: historico
2024-07-14T16:34:33.228880Z   INFO - Scale: 0
2024-07-14T16:34:33.228885Z   INFO - Containers: 0
2024-07-14T16:34:33.228890Z   INFO - Images: 1
2024-07-14T16:34:33.228925Z   INFO -   ["faaso-historico:latest"]
```

To actually run it, we need to scale it to at least 1:

```text
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

{{% tag div class="crystal" %}}
```text
$ curl 'http://localhost:8888/faaso/historico/'
Hello World Crystal!⏎
```
{{% /tag %}}


{{% tag div class="python" %}}
```text
> curl 'http://localhost:8888/faaso/historico/'
Hello World from Flask!⏎
```
{{% /tag %}}

```text
$ curl 'http://localhost:8888/faaso/historico/ping/'
OK⏎
```

By convention, funkos are always visible in `/faaso/funkoname/` and they
come with a secondary `/ping/` endpoint that should return `OK`.

Where is the code that is *doing* that? It depends on the runtime, but
usually it's called "funko" with the extension for the language of the
runtime such as `.cr` for Crystal or `.py` for Python.

{{% tag div class="crystal" %}}
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
{{% /tag %}}

{{% tag div class="python" %}}
```python
from flask import Flask, request

app = Flask("historico")

@app.route('/')
def handle():
    return "Hello World from Flask!"

@app.route('/ping')
def ping():
    return "OK"
```
{{% /tag %}}

Now, that's not really a very interesting app. Let's make it do what we want
it to do. What I want is to run some queries against my PostgreSQL database
and do some aggregations to create a data table I can use to draw a chart.

```sql
SELECT anio, contador
  FROM nombres WHERE nombre = 'juan'
```

Of course that involves a series of things:

* Have a PostgreSQL database with the data
* A user/password to connect to it
* Install the PostgreSQL client library for the language
* Get the name/names I want data on as a parameter
* Writing the code to connect to the database and run the query
* Formatting the output as JSON and returning it

If you **really** want to see this in action for yourself on your hardware,
you can make this database accessible to your funko by running this command
*in the same machine where you have the FaaSO server running*:

```text
$ docker run -ti --rm -p 5432:5432 \
  --network faaso-net --name database \
  ghcr.io/ralsina/postgres-nombres:latest

[ ... lots of output, takes a minute or five ... ]

LOG:  database system is ready to accept connections
```

{{%tag div class="crystal"%}}
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
{{%/tag%}}

{{%tag div class="python"%}}
Since we now have a database, let's get the Python client library for
PostgreSQL. In Python, you add dependencies to a `requirements.txt` file,
and your funko has one. Here, I added the `psycopg2` library:


```text
flask
psycopg2-binary
```
{{%/tag%}}


## Connecting to the Database (Using Secrets!)

What about the user/password for the database? Well, those are *secrets*.

FaaSO has a very basic secrets management system. You can add secrets
using the CLI and they are available to the funkos on runtime.

```text
$ faaso secret -a historico pass
Enter the secret, end with Ctrl-D
[...]
Secret created

$ faaso secret -a historico user
Enter the secret, end with Ctrl-D
[...]
Secret created
```

To access those secrets, the funko should read '/secrets/secretname' (in this
case, `/secrets/user` and `/secrets/pass`).

## The Working Code

The code to connect to the database and run the query is pretty simple
but beyond the scope of this tutorial:

{{% tag div class="crystal" %}}
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

  # Create result table
  results = [] of Array(String)
  results << ["Año"] + names
  (1922..2015).each do |anio|
    results << [anio.to_s]
  end
  DB.open("postgres://#{USER}:#{PASS}@database:5432/nombres") do |cursor|
    # Get the information for each name anda aggregate on the results table
    names.map do |name|
      counter_per_year = {} of Int32 => Int32
      cursor.query("
      SELECT anio::integer, contador::integer
        FROM nombres WHERE nombre = $1", name) do |result_set|
        result_set.each do
          counter_per_year[result_set.read(Int32)] = result_set.read(Int32)
        end
      end
      (1922..2015).each do |anio|
        results[anio-1921] << counter_per_year.fetch(anio,0).to_s
      end
    end
  end
  results.to_json
end

```
{{% /tag %}}

{{% tag div class="python" %}}
```python
import json

import psycopg2
from flask import Flask, request

app = Flask("historico")

USER = open("/secrets/user").read().strip()
PASS = open("/secrets/pass").read().strip()
conn = psycopg2.connect(dbname="nombres", user=USER, password=PASS, host="database")


@app.route("/", methods=["GET"])
def handle():
    names = [n.strip() for n in request.args.get("names").split(",")][:4]
    cursor = conn.cursor()
    # Prepare results table
    results = [["Año"] + names]
    results += [[year] + [0 for _ in names] for year in range(1922, 2016)]
    for i, name in enumerate(names):
        # FIXME: normalize
        cursor.execute(
            "SELECT anio, contador FROM nombres WHERE nombre = %s",
            (name,),
        )
        for anio, contador in cursor.fetchall():
            results[anio - 1921][i + 1] = contador
    cursor.close()
    return json.dumps(results)
```
{{% /tag %}}

## Redeploying and Testing

After updating the code we have to rebuild the funko and deploy it again:

```text
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

The `faaso deploy` command looks for instances of the funko running old code
and replaces them with new instances running the latest and greatest. So now we
should be able to use it! The easiest way to test is using `curl`:

```text
> curl 'http://localhost:8888/faaso/historico/?names=juan,pedro' | jq .
[
  [
    "Año",
    "juan",
    "pedro"
  ],
  [
    "1922",
    "403",
    "149"
  ],
  [
    "1923",
    "612",
    "240"
  ],
  [
    "1924",
    "790",
    "311"
  ]

[... lots more output]
```

## Frontend

Now, what can we do with the data? We can make a webpage!

FaaSO includes for convenience a very limited static file server. You can
serve `/index.html` from your funko by putting that file in a folder called
'public/' in your funko's root.

Here is some *very* basic HTML and JS fragments that uses the data we are
generating to show a chart:

```html
<html>
  <head>
    <script
      type="text/javascript"
      src="https://www.gstatic.com/charts/loader.js"
    ></script>
    <script type="text/javascript">
      google.charts.load("current", { packages: ["corechart"] });
      google.charts.setOnLoadCallback(drawChart);

      async function drawChart() {
        fetch(`http://localhost:8888/faaso/historico/?names=${document.getElementById("nombres").value}`)
          .then((response) => response.json())
          .then((json) => {
            var data = [json[0]]
            data.push(...json.slice(1).map((item) => item.map((value) => parseInt(value))));
            console.log(data)
            data = google.visualization.arrayToDataTable(data)
            var options = {
              title: "Popularidad de los nombres",
              curveType: "function",
              legend: { position: "bottom" },
            };

            var chart = new google.visualization.LineChart(
              document.getElementById("curve_chart")
            );

            chart.draw(data, options);
          });
      }
    </script>
  </head>
  <body>
    <input id="nombres"></input>
    <input type="submit" onClick="drawChart()"></input>
    <div id="curve_chart" style="width: 900px; height: 500px"></div>
  </body>
</html>
```

And yes, it does work, although of course in real life it would need
some styling so it would look [like this](https://faaso-prod.ralsina.me/faaso/historico/index.html):

![Chart, No, I don't know what happened with Leonel in 1975](chart.png)

## Funko Options

FaaSO funkos can have a few options that can be set in the `funko.yml` file.
These options vary depending on your runtime, and should be already set
to their default values. Here is the `funko.yml` file for this funko:

{{% tag div class="crystal" %}}
```yaml
name: historico
runtime: kemal
options:
  shard_build_options: ""
  ship_packages: []
  devel_packages: []
  healthcheck_options: "--interval=1m --timeout=2s --start-period=2s --retries=3"
  healthcheck_command: "curl --fail http://localhost:3000/ping || exit 1"
```
{{% /tag %}}

{{% tag div class="python" %}}
```yaml
name: historico
runtime: flask
options:
  ship_packages: []
  devel_packages: []
  healthcheck_options: "--interval=1m --timeout=2s --start-period=2s --retries=3"
  healthcheck_command: "curl --fail http://localhost:3000/ping || exit 1"
```
{{% /tag %}}

They should be explained in the documentation for each runtime, but the gist
should be more or less clear, here are some details:

The funkos are shipped in docker containers. Sometimes your code needs special
packages either to build itself (the `devel_packages` option) or to run
(the `ship_packages` option).

{{% tag div class="crystal" %}}
The `shard_build_options` is specific to Crystal and is used to pass options
to the `shards` command that compiles the code. For example `--release` will
create a smaller, faster binary ... but takes longer to compile.
{{% /tag %}}

## The Healthcheck

By default runtimes should include a `/ping` endpoint that returns `OK` and
the funko should have a healthcheck that uses that endpoint. This is important
because docker and FaaSO use this to make sure your funko is running correctly.

While the default `/ping` endpoint is very simple, you can make it more
useful by doing meaningful healthchecks. For example in historico we could
check that the database is responding:

{{% tag div class="flask" %}}
```crystal
get "/ping/" do
  DB.open("postgres://#{USER}:#{PASS}@database:5432/nombres")
    .exec("SELECT 42")
  "OK"
end
```
{{% /tag %}}
{{% tag div class="python" %}}
```python
@app.route("/ping")
def ping():
    cursor = conn.cursor()
    cursot.execute("SELECT 42")
    cursor.fetchall()
    cursor.close()
    return "OK"
```
{{% /tag %}}


## Conclusion

And that's it! You have a funko that connects to a database, gets data, and
creates a response and can be combined with a static frontend to display
the data in a nice chart.

<script>
  function switchTo(lang) {
    ['crystal', 'python', 'nodejs'].forEach((l) => {
      document.getElementById(`${l}-button`).className = "outline";
      elems = document.getElementsByClassName(l);
      for (var i = 0; i < elems.length; i++) {
        if (l === lang) {
          elems[i].style.display = 'block';
        } else {
          elems[i].style.display = 'none';
        }
      }
      document.getElementById(`${lang}-button`).className = "primary";

    });
  }
  switchTo('crystal');
</script>
