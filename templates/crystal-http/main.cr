require "http/server"
require "./function/handler"

server = HTTP::Server.new do |context|
  response_triple : NamedTuple(body: String, headers: HTTP::Headers, status_code: Int32) |
                    NamedTuple(body: String, headers: HTTP::Headers) |
                    NamedTuple(body: String, status_code: Int32) |
                    NamedTuple(body: String) |
                    NamedTuple(headers: HTTP::Headers, status_code: Int32) |
                    NamedTuple(headers: HTTP::Headers) |
                    NamedTuple(status_code: Int32)

  handler = Handler.new
  response_triple = handler.run(context.request)

  if response_triple.is_a?(NamedTuple(body: String, headers: HTTP::Headers, status_code: Int32) |
                           NamedTuple(body: String, status_code: Int32) |
                           NamedTuple(headers: HTTP::Headers, status_code: Int32) |
                           NamedTuple(status_code: Int32))
    context.response.status_code = response_triple[:status_code]
  end

  if response_triple.is_a?(NamedTuple(body: String, headers: HTTP::Headers, status_code: Int32) |
                           NamedTuple(body: String, headers: HTTP::Headers) |
                           NamedTuple(headers: HTTP::Headers, status_code: Int32) |
                           NamedTuple(headers: HTTP::Headers))
    response_triple[:headers].each do |key, value|
      context.response.headers[key] = value
    end
  end

  if response_triple.is_a?(NamedTuple(body: String, headers: HTTP::Headers, status_code: Int32) |
                           NamedTuple(body: String, headers: HTTP::Headers) |
                           NamedTuple(body: String, status_code: Int32) |
                           NamedTuple(body: String))
    context.response.print(response_triple[:body])
  end
end

server.bind_tcp "0.0.0.0", 5000
server.listen
