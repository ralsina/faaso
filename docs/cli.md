# The FaaSO Command Line Interface

The FaaSO CLI is a tool that allows you to interact with the FaaSO
platform from the command line. You can use the CLI to create,
deploy, and manage your code.

## Local Versus Remote

In some contexts, the CLI operates on your local machine. For example,
if you want to create a new funko you will use the `faaso new` command
to create a folder with code in it.

On the other hand, sometimes the CLI operates on a FaaSO server. For example,
`faaso login` makes no sense locally. What server is used is defined by the
`FAASO_SERVER` environment variable.

Finally, for some commands the CLI can operate both locally and remotely.
For example `faaso build` can build a docker image in your own machine
or in a remote server. In those cases the `--local` flag can be used to
decide where the command should run.

## Installation

You can get static binaries for the CLI from the
[releases page](github.com/ralsina/faaso/releases) both for ARM
and X86 architectures. You can also build it from source following
the [instructions in GitHub](github.com/ralsina/faaso).

Once you have a binary, put it somewhere in your PATH and you are
ready to go.

## Configuration

The CLI has no configuration except for a `.faaso.yaml` file which may
contain credentials to access a server. This file is created by the
`faaso login` command.

Also, the `FAASO_SERVER` environment variable is used when working with
a server.

## Commands

The CLI has the following commands:

* build
* deploy
* export
* help
* login
* logs
* new
* scale
* secret
* status

For help on each one, run `faaso help <command>`.
