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
Crystal has some included runtimes:

  * crystal
  * flask
  * express

Or if you have your own, use a folder name
```

So, let's create a new funko using one of the runtimes:

```bash
$  faaso new -r crystal historico
Using known runtime crystal
  Creating file historico/funko.yml from ./runtimes/crystal/template/funko.yml.j2
  Creating file historico/shard.yml from ./runtimes/crystal/template/shard.yml.j2
  Creating file historico/README.md from ./runtimes/crystal/template/README.md.j2
  Creating file historico/funko.cr from ./runtimes/crystal/template/funko.cr
```

Now you have a new folder called `historico` with the basic structure of a
funko ready for editing. We can actually just deploy it now, to verify our
whole setup works.

```bash
$ cd historico

$ faaso login
Enter password for <http://localhost:8888/admin/>
[...]

$

```
