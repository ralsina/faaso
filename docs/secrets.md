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

## Problem 2: how can the proxy know the secrets without keeping them in the image?