# frozen_string_literal: true
require_relative '../lib/availkit'
require 'socket'
require 'tmpdir'
require 'fileutils'
ID = 'a' * 32
TOKEN = 'A' * 43
KEY = 'retained-original-intent'
$assertions = 0
def assert(value, message = 'assertion failed')
  $assertions += 1
  raise message unless value
end
def assert_error(kind, code, outcome)
  begin
    yield
  rescue AvailKit::Error => e
    assert([e.kind, e.code, e.outcome] == [kind, code, outcome], "error #{e.inspect} expected #{kind}/#{code}/#{outcome}")
    assert(e.cause.nil?, 'raw error cause retained')
    assert(!e.inspect.include?(TOKEN) && !e.message.include?(TOKEN), 'secret diagnostic')
    return e
  end
  raise 'expected AvailKit error'
end
def with_server(status: 200, body: {}, headers: {}, raw_response: nil, delay: 0, &block)
  server = TCPServer.new('127.0.0.1', 0)
  requests = Queue.new; stopped = false
  thread = Thread.new do
    Thread.current.report_on_exception = false
    until stopped
      ready = IO.select([server], nil, nil, 0.05)
      next unless ready
      client = server.accept
      begin
        first = client.gets("\r\n"); next unless first
        method, path = first.split(' ')
        request_headers = {}
        while (line = client.gets("\r\n")) && line != "\r\n"
          key, value = line.split(':', 2); request_headers[key.downcase] = value.strip
        end
        bytes = client.read(request_headers.fetch('content-length', '0').to_i)
        request = {method: method, path: path, headers: request_headers, body: bytes}
        requests << request
        sleep(delay) if delay > 0
        if raw_response
          value = raw_response.respond_to?(:call) ? raw_response.call(request) : raw_response
          client.write(value) unless value.nil?
        else
          value = body.respond_to?(:call) ? body.call(request) : body
          encoded = value.is_a?(String) ? value : JSON.generate(value)
          response_headers = {'Content-Type' => 'application/json', 'Cache-Control' => 'no-store', 'Content-Length' => encoded.bytesize.to_s, 'Connection' => 'close'}.merge(headers)
          client.write("HTTP/1.1 #{status} Test\r\n" + response_headers.map { |k, v| "#{k}: #{v}\r\n" }.join + "\r\n" + encoded)
        end
      rescue IOError, SystemCallError
      ensure
        client.close
      end
    end
  end
  block.call("http://127.0.0.1:#{server.addr[1]}", requests)
ensure
  stopped = true; thread&.join; server&.close
end
def workspace(origin, **opts)
  AvailKit::Client.new(workspace_id: ID, environment: 'test', credential: TOKEN, base_url: origin, **opts)
end
def booking
  {'id' => ID, 'offeringId' => ID, 'resourceId' => ID, 'start' => '2030-01-01T09:00:00Z', 'end' => '2030-01-01T09:30:00Z', 'status' => 'confirmed'}
end
require_relative 'matrix'
def test_send_once_unknown_and_exact_replay
  sends = 0; saved = []
  responder = lambda do |request|
    sends += 1; saved << request
    next nil if sends == 1 # Commit may have occurred: response lost.
    body = JSON.generate(booking)
    "HTTP/1.1 201 Created\r\nContent-Type: application/json\r\nContent-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}"
  end
  with_server(raw_response: responder) do |origin, requests|
    c = workspace(origin)
    original = {'offeringId' => ID, 'start' => '2030-01-01T09:00:00Z'}
    intent = c.prepare_book(original, idempotency_key: KEY)
    original['start'] = '2030-01-01T10:00:00Z'
    assert(!intent.inspect.include?('09:00'), 'private intent inspect')
    Dir.mktmpdir do |dir|
      File.chmod(0o700, dir); path = File.join(dir, 'intent.json'); intent.save(path)
      assert_error('input', 'intent_persistence_failed', 'not_sent') { intent.save(path) }
      loaded = AvailKit::Intent.load(path)
      assert(sends == 0, 'prepare/load sent')
      assert_error('transport', 'request_failed', 'unknown') { c.execute(loaded) }
      assert(sends == 1, 'mutation automatically retried')
      value = c.execute(loaded)
      assert(value.start == '2030-01-01T09:00:00Z', 'original start lost')
      assert(sends == 2 && saved[0][:body] == saved[1][:body] && saved[0][:headers]['idempotency-key'] == saved[1][:headers]['idempotency-key'], 'exact original bytes/key')
      live = AvailKit::Client.new(workspace_id: ID, environment: 'live', credential: TOKEN, base_url: origin)
      assert_error('input', 'intent_scope_mismatch', 'not_sent') { live.execute(loaded) }
      assert(sends == 2, 'environment isolation sent')
      assert_error('input', 'invalid_intent_timestamp', 'not_sent') { c.execute(AvailKit::Intent.new(operation: intent.operation, path: intent.path, body: intent.body, idempotency_key: KEY, scope: intent.scope, headers: {}, created_at: (Time.now.utc + 60).iso8601)) }
      assert_error('input', 'intent_expired', 'not_sent') { c.execute(AvailKit::Intent.new(operation: intent.operation, path: intent.path, body: intent.body, idempotency_key: KEY, scope: intent.scope, headers: {}, created_at: (Time.now.utc - 86_400).iso8601)) }
    end
  end
end
def test_errors_malformed_redirect_bounds
  cases = [
    [302, {}, {'Location' => 'http://127.0.0.1:1/secret'}, 'protocol', 'invalid_response', 'unknown'],
    [403, {'error' => {'code' => 'scope_denied', 'message' => TOKEN}}, {}, 'api', 'scope_denied', 'rejected'],
    [503, {'error' => {'code' => 'unavailable', 'message' => TOKEN}}, {}, 'api', 'unavailable', 'unknown'],
    [400, {'error' => {'code' => 'private ' + TOKEN, 'message' => TOKEN}}, {}, 'api', 'api_error', 'unknown'],
    [200, '{"items":[],"nextAfter":null,"items":[]}', {}, 'protocol', 'invalid_json', 'unknown'],
    [200, {'items' => []}, {}, 'protocol', 'invalid_response', 'unknown'],
    [200, {'items' => [], 'nextAfter' => ID}, {}, 'protocol', 'invalid_response', 'unknown']
  ]
  cases.each do |status, body, headers, kind, code, outcome|
    with_server(status: status, body: body, headers: headers) do |origin, requests|
      assert_error(kind, code, outcome) { workspace(origin).list_resources }
      assert(requests.size == 1, 'retry or redirect')
    end
  end
  with_server(body: 'x' * 200) do |origin, _|
    assert_error('protocol', 'response_too_large', 'unknown') { workspace(origin, max_response_bytes: 32).list_resources }
  end
end
def test_validation_models_cancellation_and_deadline
  assert_error('input', 'invalid_input', 'not_sent') { AvailKit::Models::ResourceInput.new(name: 'x', time_zone: 'UTC') }
  model = AvailKit::Models::ResourceInput.new(name: 'Example', time_zone: 'UTC', capacity: 1)
  assert(model.name == 'Example' && model.frozen?, 'typed immutable model')
  with_server(body: {'items' => [], 'nextAfter' => nil}, delay: 0.2) do |origin, requests|
    c = workspace(origin, timeout: 0.04)
    assert_error('input', 'invalid_id', 'not_sent') { c.get_resource('../secret') }
    assert_error('input', 'invalid_input', 'not_sent') { c.create_resource({'name' => "\n", 'timeZone' => 'UTC', 'capacity' => 1}) }
    cancellation = AvailKit::Cancellation.new; cancellation.cancel
    assert_error('input', 'cancelled', 'not_sent') { c.with_request_options(cancellation: cancellation) { |x| x.list_resources } }
    assert(requests.size == 0, 'invalid input sent')
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    assert_error('transport', 'timeout', 'unknown') { c.list_resources }
    assert(Process.clock_gettime(Process::CLOCK_MONOTONIC) - start < 0.15, 'absolute deadline failed')
  end
  with_server(body: {'items' => [], 'nextAfter' => nil}, delay: 0.2) do |origin, requests|
    c = workspace(origin); cancellation = AvailKit::Cancellation.new
    canceller = Thread.new { sleep 0.04; cancellation.cancel }
    assert_error('transport', 'cancelled', 'unknown') { c.with_request_options(cancellation: cancellation) { |x| x.list_resources } }
    canceller.join; assert(requests.size == 1, 'cancellation sends')
  end
end
def test_public_scope_capabilities_and_no_cache
  with_server(body: {'id' => ID, 'title' => 'Example', 'environment' => 'live'}) do |origin, requests|
    c = AvailKit::PublicClient.new(page_id: ID, base_url: origin)
    assert(c.get_page.environment == 'live', 'page environment changed')
    request = requests.pop; assert(request[:headers]['authorization'].nil? && request[:headers]['cookie'].nil?, 'public authority')
    assert_error('input', 'invalid_guest_access', 'not_sent') { c.get_booking(ID, booking_token: 'invalid') }
    assert(requests.empty?, 'bad capability sent')
  end
  with_server(body: {'id' => ID, 'title' => 'Example', 'environment' => 'test'}, headers: {'Cache-Control' => 'public'}) do |origin, _|
    assert_error('protocol', 'invalid_response', 'unknown') { AvailKit::PublicClient.new(page_id: ID, base_url: origin).get_page }
  end
end
def test_private_files_and_webhooks
  Dir.mktmpdir do |dir|
    path = File.join(dir, 'credential'); File.write(path, TOKEN + "\n"); File.chmod(0o600, path)
    c = AvailKit::Client.new(workspace_id: ID, environment: 'test', credential_file: path)
    assert(!c.inspect.include?(TOKEN), 'client repr secret')
    File.chmod(0o644, path)
    assert_error('input', 'invalid_private_file', 'not_sent') { AvailKit::Client.new(workspace_id: ID, environment: 'test', credential_file: path) }
    File.chmod(0o600, path); File.symlink(path, path + '.link')
    assert_error('input', 'invalid_private_file', 'not_sent') { AvailKit::Client.new(workspace_id: ID, environment: 'test', credential_file: path + '.link') }
  end
  body = '{"id":"event"}'; signature = 't=1000,v1=' + OpenSSL::HMAC.hexdigest('SHA256', Base64.urlsafe_decode64(TOKEN + '='), '1000.' + body)
  assert(AvailKit.verify_webhook(body, signature, TOKEN, now: 1000), 'valid HMAC')
  assert(!AvailKit.verify_webhook(body + ' ', signature, TOKEN, now: 1000), 'exact body HMAC')
  assert(!AvailKit.verify_webhook(body, signature, TOKEN, now: 2000), 'stale HMAC')
end
def test_malformed_hours_ack_is_unknown_after_exactly_one_put
  malformed = {'windows' => [{'weekday' => 1, 'start' => '25:00', 'end' => '26:00'}]}
  request = AvailKit::Models::Hours.new(windows: [{'weekday' => 1, 'start' => '09:00', 'end' => '10:00'}])
  with_server(body: malformed) do |origin, requests|
    assert_error('protocol', 'invalid_response', 'unknown') { workspace(origin).replace_hours(ID, request) }
    assert(requests.size == 1, 'malformed hours acknowledgement automatically retried')
    wire = requests.pop
    assert(wire[:method] == 'PUT' && wire[:path] == '/v1/workspaces/' + ID + '/resources/' + ID + '/hours', 'hours mutation route')
    assert(JSON.parse(wire[:body]) == request.to_wire, 'hours original intent body')
  end
end
def test_workspace_example_refuses_live_before_reading_configuration
  example = File.expand_path('../examples/first-booking.rb', __dir__)
  output = IO.popen([{'AVAILKIT_ENVIRONMENT' => 'live', 'AVAILKIT_CREDENTIAL_FILE' => '/never/read/credential'}, RbConfig.ruby, '-I' + File.expand_path('../lib', __dir__), example], err: [:child, :out], &:read)
  assert(!$?.success?, 'live tutorial was admitted')
  assert(output.include?('Example requires AVAILKIT_ENVIRONMENT=test'), 'live tutorial did not stop before configuration')
end
private_methods.grep(/^test_/).sort.each do |name|
  send(name)
  puts "PASS #{name}"
end
puts "PASS #{$assertions} assertions; 41 operation HTTP matrix plus lifecycle/fault checks"
