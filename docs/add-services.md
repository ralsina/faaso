# How to Provide Services to FaaSO

Sometimes you want to provide your FaaSO applications with things
that are not provided, like a database, or a cache.

Since FaaSO does no magical things, it turns out this is pretty easy.

## Solution 1: Just run it and use it

Just run that service (postgres, redis, whatever) in a place accessible
from your FaaSO server and let the FaaSO applications use it. FaaSO
doesn't limit their outgoing connections, so they can connect to
anything that is reachable.

## Solution 2: Run it "inside FaaSO"

All FaaSO applications run in containers in the `faaso-net` network.
So, as long as your service is also in a container in the same
network, It Just Works®

For example, in the [Funko dev tutorial](funko-dev.html), we run
a PostgreSQL database with the data needed for the example app
like this:

```
docker run -ti --rm -p 5432:5432 \
  --network faaso-net --name database \
  ghcr.io/ralsina/postgres-nombres:latest
```

You don't even need the `-p 5443:5432` if you don't
want to access the database from outside FaaSO.

## Future Options

In the far future there *may* be a way to run random services
inside FaaSO, but that's not a priority right now.
