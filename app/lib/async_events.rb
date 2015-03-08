require 'faye/websocket'
require 'thread'
require 'json'
require 'erb'

# https://github.com/heroku-examples/ruby-websockets-chat-demo/blob/master/middlewares/chat_backend.rb
# https://github.com/curoverse/arvados/blob/master/services/api/lib/eventbus.rb

class AsyncEvents
  KEEPALIVE_TIME = 1 # in seconds
  CHANNEL = "chatdemo"

  def initialize(app)
    @app     = app
    @clients = []

    @mutex = Mutex.new
    @bgthread = false
  end

  def call(env)
    return @app.call(env) unless Faye::WebSocket.websocket?(env)

    setup_listener

    ws = Faye::WebSocket.new(env, nil, { ping: KEEPALIVE_TIME })
    ws.on :open do |event|
      p [:open, ws.object_id]
      @clients << ws
    end

    ws.on :message do |event|
      p [:message, event.data]
      data = JSON.parse event.data
      message = Message.create author: data['author'], body: data['body']
      p data
    end

    ws.on :close do |event|
      p [:close, ws.object_id, event.code, event.reason]
      @clients.delete(ws)
      ws = nil
    end

    # Return async Rack response
    ws.rack_response
  end

  def setup_listener
    # Start up thread to monitor the Postgres database, if none exists already.
    @mutex.synchronize do
      unless @bgthread
        @bgthread = true
        Thread.new do
          # from http://stackoverflow.com/questions/16405520/postgres-listen-notify-rails
          ActiveRecord::Base.connection_pool.with_connection do |connection|
            conn = connection.instance_variable_get(:@connection)
            begin
              conn.async_exec "LISTEN #{CHANNEL}"
              loop do
                conn.wait_for_notify do |channel, pid, payload|
                  p [:send, payload]
                  @clients.each {|ws| ws.send(sanitize payload) }
                end
              end
            rescue => error
              p [:error, error]
            ensure
              # Don't want the connection to still be listening once we return
              # it to the pool - could result in weird behavior for the next
              # thread to check it out.
              conn.async_exec "UNLISTEN *"
              p [:unlisten]
            end
          end
          @bgthread = false
        end
      end
    end
  end

  private
  def sanitize(message)
    json = JSON.parse(message)
    json.each {|key, value| json[key] = ERB::Util.html_escape(value) }
    JSON.generate(json)
  end
end
