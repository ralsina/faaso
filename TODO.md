# Things that need doing before first release

* User flow for initial proxy setup
  * Setting up password
  * Setting up hostname for Caddy's automatic HTTPS
* Config UI in frontend?
* Support tokens besides basic auth
* Polish frontend UI **A LOT**
* Version checks for consistency between client/server
* Have 3 runtimes:
  * Crystal + Kemal ✅
  * Python + Flask [WIP]
  * Nodejs + Express
* Document
  * How to create a runtime
  * How to create a funko
  * How to setup the proxy
  * APIs
* Sanitize all inputs
* Streaming responses in slow operations like scaling down
  or building
* Make more things configurable / remove hardcoded stuff
* CD for binaries and images for at least arm64/x86
* Multi-container docker logs
