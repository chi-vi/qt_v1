require "log"
require "action-controller"
require "action-controller/logger"
require "action-controller/server"

abstract class UserError < Exception
  getter status : HTTP::Status = :bad_request

  def initialize(@message)
    @cause = nil
    @callstack = nil
  end
end

class BadRequest < UserError
  def initialize(message)
    super(message)
    @status = :bad_request
  end
end

class Unauthorized < UserError
  def initialize(message)
    super(message)
    @status = :unauthorized
  end
end

class Forbidden < UserError
  def initialize(message)
    super(message)
    @status = :forbidden
  end
end

class NotFound < UserError
  def initialize(@message)
    @status = :not_found
  end
end

abstract class AC::Base
  # add_responder("text/plain") { |io, result| io << result }
  # add_responder("text/html") { |io, result| io << result }

  @[AC::Route::Filter(:before_action)]
  def before_all_actions
    response.headers["Date"] = HTTP.format_time(Time.utc)
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type"
    response.headers["Content-Type"] = "application/json"
    response.headers["Access-Control-Allow-Methods"] = "GET,HEAD,POST,DELETE,OPTIONS,PUT,PATCH"

    Log.context.set(client_ip: client_ip)
  end
end

def start_server!(port : Int32, server_name : String)
  # Add handlers that should run before your application
  AC::Server.before(AC::LogHandler.new)

  server = AC::Server.new(port, "127.0.0.1")
  server.run { puts "[#{server_name}] listening on #{server.print_addresses}" }

  # finished
  puts "[#{server_name}] server terminated"
end

require "./_srv/*"
start_server!(6666, "oldmt")
