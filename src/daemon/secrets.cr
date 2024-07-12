require "kemal"
require "../secrets.cr"

module Secrets
  extend self
  # TODO: sanitize all inputs

  # Gets a secret in form {"name": "funko_name-secret_name", "value": "secret_value"}
  post "/secrets/" do |env|
    pp! env.params
    funko = env.params.body["funko"].as(String)
    name = env.params.body["name"].as(String)
    value = env.params.body["value"].as(String)
    Log.info { "Creating secret #{funko}-#{name}" }
    if funko.empty? || name.empty? || value.empty?
      halt env, status_code: 400, response: "Bad request"
    end
    SECRETS["#{funko}-#{name}"] = value
    Secrets.update_secrets
    halt env, status_code: 201, response: "Created"
  end

  get "/secrets/" do |env|
    result = [] of Hash(String, String)
    SECRETS.each { |k, _|
      result << {
        "funko" => k.split("-")[0],
        "name"  => k.split("-", 2)[1],
      }
    }
    if env.params.query.fetch("format", "json") == "html"
      render "src/views/secrets.ecr"
    else
      result.to_json
    end
  end

  # Deletes a secret from the disk and memory
  get "/secrets/:funko/:name/" do |env|
    funko = env.params.url["funko"]
    name = env.params.url["name"]

    if funko == name == "-"
      result = {"funko" => "", "name" => ""}
    else
      # We never give up the secrets value over HTTP
      result = {"funko" => funko,
                "name"  => name,
      }
    end

    if env.params.query.fetch("format", "json") == "html"
      render "src/views/secret_dialog.ecr"
    else # This is pretty useless ;-)
      result.to_json
    end
  end

  # Deletes a secret from the disk and memory
  delete "/secrets/:funko/:name/" do |env|
    funko = env.params.url["funko"]
    name = env.params.url["name"]
    SECRETS.delete("#{funko}-#{name}")
    update_secrets
    halt env, status_code: 204, response: "Deleted"
  end
end

Secrets.load_secrets
