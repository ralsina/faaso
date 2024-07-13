# TODO LIST

## Things that need doing before first release

* ✅ User flow for initial proxy setup
  * ✅ Setting up password
* Polish frontend UI **A LOT**
  * ✅ Make secrets work correctly
  * Add UI for scaling funkos rather than "play/stop"
  * Add tooltips where appropriate
  * ✅ Nicer icons
  * Maybe tabbed UI?
  * Add UI for vhosts when ready
  * Don't use CDNs
* ✅ Version checks for consistency between client/server
* ✅ Have 3 runtimes:
  * ✅ Crystal + Kemal
  * ✅ Python + Flask
  * ✅ Nodejs + Express
* ✅ Create a site
  * Document
    * FaaSO for app developers
    * FaaSO for runtime developers
    * FaaSO server setup
    * APIs
* Sanitize all inputs
* ✅ Streaming responses in slow operations
* ✅ Make more things configurable / remove hardcoded stuff
  * ✅ Make server take options from file
  * ✅ Make server take options from environment
  * ✅ Make server password configurable
  * ✅ admin/admin auth client side
  * ✅ `faaso login` is not working properly yet with proxy
* CD for binaries and images for at least arm64/x86
* ✅ Configurable verbosity, support stderr/stdout split
* ✅ Fix proxy reload / Make it reload on file changes
* Implement `faaso help command`
* ✅ Fix `export examples/hello_crystal` it has a `template/`
* ✅ Implement zero-downtime rollout (`faaso deploy`)
* ✅ Cleanup `tmp/whatever` after use
* ✅ `faaso scale` remote is broken
* ✅ Setup linters/pre-commit/etc
* ✅ Implement secret editing
* Check secret permissions (maybe run proxy as non-root)
* ✅ Check if deploy is working correctly in different scenarios
* Implement static site vhost proxying
* ✅ Multi-container docker logs [faaso logs -f FUNKO]

## Things to do but not before release

* Propagate errors from `run_faaso` to the remote client
* Setting up hostname for Caddy's automatic HTTPS
* Config UI in frontend?
* Add multi-container logs to web frontend. It's close but
  haven't figured out how to make HTMX append the log into
  an element and show newlines correctly.
* Polish secret dialog to show correct wording in title and buttons,
  maybe disable funko/name inputs when editing?
