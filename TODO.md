# Things that need doing before first release

* User flow for initial proxy setup
  * ✅ Setting up password
  * Setting up hostname for Caddy's automatic HTTPS
* Config UI in frontend?
* Polish frontend UI **A LOT**
* ✅ Version checks for consistency between client/server
* ✅ Have 3 runtimes:
  * ✅ Crystal + Kemal
  * ✅ Python + Flask
  * ✅ Nodejs + Express
* Document
  * How to create a runtime
  * How to create a funko
  * How to setup the proxy
  * APIs
* Sanitize all inputs
* ✅ Streaming responses in slow operations like scaling down
  or building
* ✅ Make more things configurable / remove hardcoded stuff
  * ✅ Make server take options from file
  * ✅ Make server take options from environment
  * ✅ Make server password configurable
  * ✅ admin/admin auth client side
  * ✅ `faaso login` is not working properly yet with proxy
* CD for binaries and images for at least arm64/x86
* Multi-container docker logs [faaso logs -f FUNKO]
* ✅ Direct error and above to stderr, others to stdout,
  while keeping logging level configurable
* ✅ Fix proxy reload / Make it reload on file changes
* Implement `faaso help command`
* Fix `export examples/hello_crystal` it has a `template/`
* ✅ Implement zero-downtime rollout (`faaso deploy`)
* Cleanup `tmp/` after use unless `DEBUG` is set

# Things to do but not before release

* Propagate errors from `run_faaso` to the remote client 