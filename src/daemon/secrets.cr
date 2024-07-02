require "kemal"
require "../secrets.cr"

module Secrets
  extend self
  # TODO: sanitize all inputs

  # Gets a secret in form {"name": "funko_name-secret_name", "value": "secret_value"}
  post "/secrets/" do |env|
    name = env.params.json["name"].as(String)
    value = env.params.json["value"].as(String)
    SECRETS[name] = value
    Secrets.update_secrets
    halt env, status_code: 201, response: "Created"
  end

  get "/secrets/" do |env|
    halt env, status_code: 200, response: SECRETS.keys.to_json
  end

  # Deletes a secret from the disk and memory
  delete "/secrets/:name/" do |env|
    name = env.params.url["name"]
    SECRETS.delete(name)
    update_secrets
    halt env, status_code: 204, response: "Deleted"
  end
end

Secrets.load_secrets
