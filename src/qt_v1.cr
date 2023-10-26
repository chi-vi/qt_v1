require "log"
require "action-controller"
require "action-controller/logger"
require "action-controller/server"

class ::Log
  backend = IOBackend.new(STDOUT)
  time_zone = Time::Location.load("Asia/Ho_Chi_Minh")

  backend.formatter = Formatter.new do |entry, io|
    io << entry.timestamp.in(time_zone).to_s("%I:%M:%S")
    io << ' ' << entry.source << " |"
    io << " (#{entry.severity})" if entry.severity > Severity::Debug
    io << ' ' << entry.message

    if entry.severity == Severity::Error
      io << '\n'
      entry.exception.try(&.inspect_with_backtrace(io))
    end
  end

  builder.clear

  if ENV["ENV"]? == "production"
    log_level = ::Log::Severity::Info
    builder.bind "*", :warn, backend
  else
    log_level = ::Log::Severity::Debug
    builder.bind "*", :info, backend
  end

  setup_from_env
end

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

  #####

  @[AlwaysInline]
  private def _read_cookie(name : String)
    cookies[name]?.try(&.value)
  end

  @[AlwaysInline]
  private def _cfg_enabled?(name : String)
    cookies[name]?.try(&.value.starts_with?('t')) || false
  end

  @[AlwaysInline]
  private def _read_body
    request.body.try(&.gets_to_end) || ""
  end

  private def _paginate(min = 5, max = 100)
    pg_no = params["pg"]?.try(&.to_i?) || 1
    limit = params["lm"]?.try(&.to_i?) || min

    pg_no = 1 if pg_no < 1
    limit = max if limit > max

    {pg_no, limit, (pg_no &- 1) &* limit}
  end

  private def _paged(pg_no : Int, limit : Int, max : Int)
    limit = max if limit > max
    _paged(pg_no, limit)
  end

  private def _paged(pg_no : Int, limit : Int)
    pg_no = 1 if pg_no < 1
    {limit, limit &* (pg_no &- 1)}
  end

  private def _pgidx(total : Int, limit : Int)
    (total &- 1) // limit &+ 1
  end

  def cache_control(max_age : Time::Span | Time::MonthSpan, extra : String = "public")
    cache_control(max_age.total_seconds.to_i, extra: extra)
  end

  def cache_control(max_age : Int32 = 5, extra : String = "public")
    response.headers["Cache-Control"] = "max-age=#{max_age}, #{extra}"
  end

  def add_etag(etag : String | Int)
    response.headers["ETag"] = %{"#{etag}"}
  end
end

class ErrorHandler
  include HTTP::Handler

  def call(context : HTTP::Server::Context)
    call_next(context)
  rescue ex : Exception
    response = context.response
    response.reset

    if ex.is_a?(UserError)
      response.status = ex.status
    else
      response.status = :internal_server_error
    end

    response.content_type = "text/plain; charset=utf-8"
    response.print(ex.message)
  end
end

def start_server!(port : Int32, server_name : String)
  # Add handlers that should run before your application
  AC::Server.before(AC::LogHandler.new, HTTP::CompressHandler.new, ErrorHandler.new)

  server = AC::Server.new(port, "127.0.0.1")

  terminate = Proc(Signal, Nil).new do |signal|
    signal.ignore
    server.close
    # puts " > terminating gracefully"
    # spawn { server.close }
  end

  Signal::INT.trap &terminate  # Detect ctr-c to shutdown gracefully
  Signal::TERM.trap &terminate # Docker containers use the term signal

  server.run { puts "[#{server_name}] listening on #{server.print_addresses}" }

  # finished
  puts "[#{server_name}] server terminated"
end

require "./_srv/*"
start_server!(6666, "oldmt")
