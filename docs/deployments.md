# Braindump on deployments

Problem: We have a funko, we want it deployed.

## Variant 1: Local deployment

Solution: Just start the funko's container locally. Done. It's mostly implemented.

## Variant 2: Deploy to the server

If the server doesn't have the image, we have "server build", so assume the image
is there.

Solution: start the funko on the server. Done. It's implemented.

## Variant 3: Deploy to the server and it's already running

1. If it's already running and it's running the latest image, then nothing to be done.
2. It it's running and is not the latest, we can stop it and start with the latest image.

* Action 2 causes downtime. Usually it will not be significant, but it's there.
* In the future it may be important to have zero downtime.
* We need to figure out what is implied by doing "zero downtime" to see if
  not doing it now would make it impossible.

For zero downtime, we want to have two instances running, switch the proxy to the new
one, then stop the old one.

Currently it's impossible to run two instances because the container name is
faaso-funkoname, and we can't have 2 of those.

So: we could instead have faaso-funkoname-1, faaso-funkoname-2, etc. with some sort of suffix

Changes implied in the faaso code:

* If we have two containers for one funko, we need to consider the "state" of 
  the funko differently.
* What does it mean to start/pause/stop a funko with two instances
* Do we want to enable two-instance funkos? With round-robin proxy?
* What happens if we have two instances with different images?

Answers coming up.






