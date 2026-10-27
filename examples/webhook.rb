# frozen_string_literal: true
require 'availkit'
require 'socket'
require 'timeout'
# Verification tutorial only. Durable handlers must transactionally dedupe
# AvailKit-Delivery-ID together with their own domain update before returning2xx.
secret = ENV.fetch('AVAILKIT_WEBHOOK_SECRET')
server = TCPServer.new('127.0.0.1', 8766)
loop do
  socket = server.accept
  status = 400
  begin
    Timeout.timeout(3) do
      first = socket.gets("\r\n", 2048)
      raise ArgumentError unless first == "POST /webhook HTTP/1.1\r\n"
      headers = {}; count = 0
      loop do
        line = socket.gets("\r\n", 4096); raise ArgumentError unless line
        break if line == "\r\n"
        count += line.bytesize; raise ArgumentError if count > 8192
        key, value = line.split(':', 2); raise ArgumentError unless value
        key = key.downcase; raise ArgumentError if headers.key?(key)
        headers[key] = value.strip
      end
      length = headers['content-length']
      raise ArgumentError unless length && /\A\d+\z/.match?(length) && length.to_i <= 16_384 && !headers.key?('transfer-encoding')
      raw = socket.read(length.to_i); raise ArgumentError unless raw && raw.bytesize == length.to_i
      status = AvailKit.verify_webhook(raw, headers['availkit-signature'], secret) ? 204 : 401
    end
  rescue StandardError
    status = 400
  ensure
    begin
      socket.write("HTTP/1.1 #{status} Result\r\nContent-Length: 0\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n")
    rescue IOError, SystemCallError
    end
    socket.close
  end
end
