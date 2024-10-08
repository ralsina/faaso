# TODO LIST

## Things that need doing before next release

* ✅ Persistence of scaling
* Pulling from a configurable registry for missing image names
* A "local run" mode for debugging/development
* Make proxy start without explicit configuration
* Get rid of multirun
* ✅ Propagate errors from `run_faaso` to the remote client
* Setting up hostname for Caddy's automatic HTTPS
* Config UI in frontend?
* Add multi-container logs to web frontend. It's close but
  haven't figured out how to make HTMX append the log into
  an element and show newlines correctly.
* Polish secret dialog to show correct wording in title and buttons,
  maybe disable funko/name inputs when editing?
* Metrics from Caddy using Prometheus (or something)
* Implement static site vhost proxying
* Add UI for scaling funkos rather than "play/stop"
* Explore swarm integration for horizontal scaling
* Check compatibility with podman
* Remove the docker dependency in the proxy image (saves about 250MB!)
* Design gitops workflow
* Document and/or redesign APIs
* Update tooling to my current preference (Hacé + release script + git cliff)

## Things that need doing before first release

* ✅ User flow for initial proxy setup
  * ✅ Setting up password
* ✅ Polish frontend UI **A LOT**
  * ✅ Make secrets work correctly
  * ✅ Add tooltips where appropriate
  * ✅ Nicer icons
  * ✅ Maybe tabbed UI?
  * ✅ Confirmation before destructive actions
* ✅ Version checks for consistency between client/server
* ✅ Have 3 runtimes:
  * ✅ Crystal + Kemal
  * ✅ Python + Flask
  * ✅ Nodejs + Express
* ✅ Create a site
  * Document
    * ✅ Review all server setup doc
    * ✅ Tutorial with a non-trivial app
      * ✅ Kemal
      * ✅ Express
      * ✅ Flask
      * ✅ Document static index.html in example
      * ✅ Fix problem with names missing rows (lionel)
      * ✅ Document runtime options
    * ✅ FaaSO for runtime developers
    * ✅ FaaSO server setup
    * ✅ CLI
    * ✅ Front End
    * ✅ Caddyfile hostname quirks
* ✅ Sanitize inputs
* ✅ Streaming responses in slow operations
* ✅ Make more things configurable / remove hardcoded stuff
  * ✅ Make server take options from file
  * ✅ Make server take options from environment
  * ✅ Make server password configurable
  * ✅ admin/admin auth client side
  * ✅ `faaso login` is not working properly yet with proxy
* CD for binaries and images for at least arm64/x86
  * ✅ Script to build static binaries
  * ✅ Script to build docker images and upload to registry
  * Run it on release
* ✅ Configurable verbosity, support stderr/stdout split
* ✅ Fix proxy reload / Make it reload on file changes
* ✅ Fix `export examples/hello_crystal` it has a `template/`
* ✅ Implement zero-downtime rollout (`faaso deploy`)
* ✅ Cleanup `tmp/whatever` after use
* ✅ `faaso scale` remote is broken
* ✅ Setup linters/pre-commit/etc
* ✅ Implement secret editing
* ✅ Check secret permissions (maybe run proxy as non-root)
* ✅ Check if deploy is working correctly in different scenarios
* ✅ Multi-container docker logs [faaso logs -f FUNKO]
* ✅ Implement `faaso help command`
* ✅ Switch from rucksack to something else because it's flaky
* ✅ Nicer `faaso login`behaviour
* ✅ Fix `faaso secret` input issues
* ✅ Add --no-cache option for faaso build
* ✅ Support generic runtime-defined options for templates
* ✅ Empty enumerable error in latest_image
* ✅ Make Historico work well in test server
* ✅ Add button to close terminal / logs
* ✅ Special case proxy in web UI
* ✅ Make status better (add -a to show all, skip proxy)
* ✅ Tag images with something like `faaso-hello:timestamp` besides latest
* ✅ Spinoff multi-docopt code into a shard
* ✅ Display container health in web UI
* ✅ Fix the web UI's code for deleting a funko, generalize, make CLI
* ✅ Re-record video properly (claim it in asciinema, use doitlive)
* ✅ faaso logs seems to always be local
* ✅ Use <https://github.com/ysbaddaden/pool> in the kemal historico example
* ✅ Streaming responses from server are choppy
* ✅ Add "copy_from_build" option in funko.yml
* ✅ Migrate to polydocopt
* ✅ Fix flask static serving
* ✅ Update flask/express Dockerfile to match kemal
* ✅ Add --name option to faaso build
