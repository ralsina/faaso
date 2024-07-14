# Ideas about secret management

It's a bad idea to store secrets in a docker image.

However, code running in docker containers like a funko does often needs
access to secrets, such as passwords to databases. Let's use that as the
example secret for the rest of the document.

Also, not all funkos should have access to all the secrets, and the
"need to know" should be declarative in the funko's metadata.

## Problem 1: accessing secrets in the proxy container from the funkos

Let's further assume that faaso-proxy has access *somehow* to all the secrets,
identified by a name. So there is a "dbpass" secret that has "verysecret" as
it's very secret content.

Also let's assume the proxy has access to a folder in the server filesystem,
`/secrets` via something like a bind mount.

If the proxy has access to the funko metadata, it can access a declaration of
what secrets the funko needs.

Alternatively ... convention!

Secrets for the funko foo are called foo-{name}, so our example is called foo-dbpass.

So, the proxy can periodically examine its secret store and populate a folder
`/secrets/foo` with a `dbpass` file containing "verysecret".

If on starting a funko we always do a bind mount of `/secrets/foo` to `/secrets`
then it will always have its secrets in place.

## Problem 2: how can the proxy know the secrets without keeping them in the image

They can't be shipped via the image, so they need to be injected via the admin API.

Let's give it a /secret endpoint and have all the usual REST stuff there.

## The Good

* It should work
* No secrets are unencrypted at rest in images

## The Bad

* Secrets are unencrypted at rest in the server filesystem
* Secrets are only sort-of-persistent? If the proxy is restarted, it will need
  the secrets reinjected, or we need a persistent secret store in the server filesystem.
