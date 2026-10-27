# frozen_string_literal: true
require 'json'
require 'net/http'
require 'uri'
require 'openssl'
require 'base64'
require 'securerandom'
require 'time'
require 'timeout'
require 'digest'
require 'thread'
require 'ipaddr'

module AvailKit
  VERSION = '0.1.1'
  SCHEMAS = JSON.parse(File.read(File.join(__dir__, 'availkit/schemas.json'))).freeze
  OPERATIONS = JSON.parse(File.read(File.join(__dir__, 'availkit/operations.json'))).freeze
  ID = /\A[0-9a-f]{32}\z/
  TOKEN = /\A[A-Za-z0-9_-]{42}[AEIMQUYcgkosw048]\z/
  STAMP = /\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d{1,9})?Z\z/
  KEY = /\A[\x20-\x7e]{16,128}\z/
  REPLAY = %w[book cancel rescheduleBooking bookPublic cancelPublicBooking reschedulePublicBooking].freeze
  SAFE_CODES = %w[booking_page_paused booking_access_in_use contact_changed validation_failed synthetic_email_required unauthorized forbidden scope_denied not_found invalid_input invalid_query invalid_cursor invalid_limit quota_exceeded unavailable credential_invalid capability_denied customer_archived idempotency_conflict capacity_conflict capacity_exceeded version_conflict catalog_in_use catalog_archived event_cursor_expired invalid_id invalid_range identity_unavailable recovery_unavailable csrf_invalid recent_auth_required secret_already_revealed idempotency_mismatch membership_changed membership_denied last_credential identity_limit identity_rate_limited membership_conflict request_key_invalid].freeze

  # Never attach the original HTTP exception, URL, headers, caller data or body.
  class Error < StandardError
    attr_reader :kind, :code, :status, :outcome
    def initialize(kind, code, status = nil)
      @kind, @code, @status = kind, code, status
      @outcome = kind == 'input' ? 'not_sent' : (kind == 'api' && status && (400...500).cover?(status) && code != 'api_error' ? 'rejected' : 'unknown')
      super("AvailKit #{kind} error (#{code})")
    end
    def to_h = {kind: kind, code: code, status: status, outcome: outcome}
    def inspect = "#<AvailKit::Error #{kind}/#{code} outcome=#{outcome}>"
  end
  def self.fail_input(code = 'invalid_input') = raise(Error.new('input', code), cause: nil)
  def self.instant(v)
    raise ArgumentError unless v.is_a?(String) && STAMP.match?(v)
    Time.iso8601(v)
  end
  def self.text?(v, max = 160) = v.is_a?(String) && v.valid_encoding? && !v.strip.empty? && v.length <= max && !v.match?(/[[:cntrl:]]/)
  def self.identifier(v)
    fail_input('invalid_id') unless v.is_a?(String) && ID.match?(v)
    v
  end
  def self.new_idempotency_key = SecureRandom.urlsafe_base64(24, false)
  def self.new_guest_token = SecureRandom.urlsafe_base64(32, false)
  def self.key!(v)
    fail_input('invalid_idempotency_key') unless v.is_a?(String) && KEY.match?(v) && v.strip == v
    v
  end
  def self.freeze_value(v)
    case v
    when Hash then v.each { |k, x| k.freeze; freeze_value(x) }
    when Array then v.each { |x| freeze_value(x) }
    end
    v.freeze
  end
  # Strict JSON parser: duplicate keys, NaN, invalid UTF-8 and nesting rejected.
  def self.finite_json?(value)
    case value
    when Float then value.finite?
    when Hash then value.values.all? { |x| finite_json?(x) }
    when Array then value.all? { |x| finite_json?(x) }
    else true
    end
  end
  def self.unique_json!(tokens, position = [0], depth = 0)
    raise JSON::ParserError, 'depth' if depth > 24
    token = tokens[position[0]]; position[0] += 1
    if token == '{'
      seen = {}
      unless tokens[position[0]] == '}'
        loop do
          key = JSON.parse(tokens.fetch(position[0])); position[0] += 1
          raise JSON::ParserError, 'duplicate key' if seen.key?(key)
          seen[key] = true
          raise JSON::ParserError, 'colon' unless tokens[position[0]] == ':'
          position[0] += 1; unique_json!(tokens, position, depth + 1)
          break unless tokens[position[0]] == ','
          position[0] += 1
        end
      end
      raise JSON::ParserError, 'object end' unless tokens[position[0]] == '}'
      position[0] += 1
    elsif token == '['
      unless tokens[position[0]] == ']'
        loop do
          unique_json!(tokens, position, depth + 1)
          break unless tokens[position[0]] == ','
          position[0] += 1
        end
      end
      raise JSON::ParserError, 'array end' unless tokens[position[0]] == ']'
      position[0] += 1
    end
    position[0]
  end
  def self.decode(raw)
    raw = raw.dup.force_encoding(Encoding::UTF_8)
    raise JSON::ParserError, 'encoding' unless raw.valid_encoding?
    value = JSON.parse(raw, max_nesting: 24, allow_nan: false)
    raise JSON::ParserError, 'nonfinite' unless finite_json?(value)
    # Ruby JSON versions prior to duplicate-key rejection support silently keep
    # the last value, even for a custom object_class. Check exact decoded keys
    # separately so behavior is consistent on every supported Ruby runtime.
    tokens = raw.scan(/"(?:[^"\\]|\\.)*"|[{}\[\],:]|[^\s{}\[\],:]+/)
    raise JSON::ParserError, 'trailing' unless unique_json!(tokens) == tokens.length
    value
  rescue IndexError, TypeError
    raise JSON::ParserError, 'invalid JSON'
  end
  def self.validate(v, s, depth = 0)
    return false if depth > 20
    s = SCHEMAS.fetch(s) if s.is_a?(String)
    return validate(v, s.fetch('$ref').split('/').last, depth + 1) if s.key?('$ref')
    return false if s.key?('allOf') && !s['allOf'].all? { |x| validate(v, x, depth + 1) }
    return false if s.key?('anyOf') && !s['anyOf'].any? { |x| validate(v, x, depth + 1) }
    return false if s.key?('oneOf') && s['oneOf'].count { |x| validate(v, x, depth + 1) } != 1
    return false if s.key?('const') && (v.class != s['const'].class || v != s['const'])
    return false if s.key?('enum') && !s['enum'].any? { |x| x.class == v.class && x == v }
    kinds = Array(s['type'])
    checks = {'null' => -> { v.nil? }, 'object' => -> { v.is_a?(Hash) }, 'array' => -> { v.is_a?(Array) }, 'string' => -> { v.is_a?(String) }, 'integer' => -> { v.is_a?(Integer) }, 'boolean' => -> { v == true || v == false }, 'number' => -> { v.is_a?(Numeric) && v.finite? }}
    return false if !kinds.empty? && !kinds.any? { |k| checks.fetch(k).call }
    case v
    when Hash
      props = s.fetch('properties', {})
      return false unless s.fetch('required', []).all? { |k| v.key?(k) }
      return false if s['additionalProperties'] == false && (v.keys - props.keys).any?
      v.all? do |k, x|
        id_valid = !%w[id resourceId offeringId customerId pageId subscriptionId eventId bookingId].include?(k) || x.nil? || x.is_a?(String) && ID.match?(x)
        secret_valid = k != 'signingSecret' || x.is_a?(String) && TOKEN.match?(x)
        id_valid && secret_valid && (!props.key?(k) || validate(x, props[k], depth + 1))
      end
    when Array
      (s.fetch('minItems', 0)..s.fetch('maxItems', 10_000)).cover?(v.length) && v.all? { |x| validate(x, s.fetch('items', {}), depth + 1) }
    when String
      return false unless (s.fetch('minLength', 0)..s.fetch('maxLength', 8192)).cover?(v.length)
      return false if s.key?('pattern') && !Regexp.new(s['pattern']).match?(v)
      instant(v) if s['format'] == 'date-time'
      true
    when Numeric then (s.fetch('minimum', -9_007_199_254_740_991)..s.fetch('maximum', 9_007_199_254_740_991)).cover?(v)
    else true
    end
  rescue ArgumentError, RangeError
    false
  end
  def self.input_body(v, s)
    return nil if s.nil? && v.nil?
    v = v.to_wire if v.is_a?(Model)
    fail_input unless s && validate(v, s)
    raw = JSON.generate(v, allow_nan: false)
    fail_input('body_too_large') if raw.bytesize > 16_384
    semantic_input!(v, s)
    raw.freeze
  rescue JSON::GeneratorError, EncodingError, TypeError
    fail_input('invalid_json')
  end
  def self.semantic_input!(v, s)
    name = s.fetch('$ref', '').split('/').last
    case name
    when 'ResourceInput'
      fail_input unless text?(v['name']) && text?(v['timeZone'], 100)
    when 'OfferingInput'
      fail_input unless text?(v['name']); identifier(v['resourceId'])
    when 'BookingInput', 'PublicBookingInput'
      identifier(v['offeringId'])
      semantic_input!(v['contact'], {'$ref' => '#/components/schemas/CustomerInput'}) if name == 'PublicBookingInput'
    when 'CustomerInput'
      fail_input('invalid_customer') unless text?(v['displayName'])
      fail_input('invalid_customer') if !v['email'].nil? && (!text?(v['email'], 254) || !v['email'].match?(/\A[^@\s]+@[^@\s]+\z/))
      fail_input('invalid_customer') if !v['phone'].nil? && !text?(v['phone'], 32)
    when 'BookingPageInput' then fail_input unless text?(v['title'])
    when 'WebhookCreate'
      begin
        u = URI.parse(v['url']); ip = begin; IPAddr.new(u.hostname); true; rescue IPAddr::InvalidAddressError; false; end
        fail_input('invalid_webhook_url') unless u.scheme == 'https' && u.host && !u.userinfo && !u.query && !u.fragment && u.port == 443 && !ip
      rescue URI::Error, ArgumentError, TypeError
        fail_input('invalid_webhook_url')
      end
    when 'Hours'
      v['windows'].each_with_index do |w, i|
        fail_input('invalid_hours') unless /\A(?:[01]\d|2[0-3]):[0-5]\d\z/.match?(w['start']) && /\A(?:(?:[01]\d|2[0-3]):[0-5]\d|24:00)\z/.match?(w['end']) && w['start'] < w['end']
        fail_input('invalid_hours') if v['windows'].take(i).any? { |x| x['weekday'] == w['weekday'] && x['start'] < w['end'] && w['start'] < x['end'] }
      end
    end
  end

  # Immutable language-appropriate keyword models. Optional fields distinguish
  # absence from explicit null. Responses contain nested Models/immutable arrays.
  class Model
    def initialize(**kwargs)
      fields = self.class::FIELDS
      AvailKit.fail_input unless (kwargs.keys.map(&:to_s) - fields.keys).empty?
      wire = kwargs.to_h { |k, v| [fields.fetch(k.to_s), self.class.wire_value(v)] }
      AvailKit.fail_input unless AvailKit.validate(wire, self.class::SCHEMA_NAME)
      @wire = AvailKit.freeze_value(wire)
      fields.each { |ruby, json| instance_variable_set('@' + ruby, self.class.model_value(wire[json], AvailKit::SCHEMAS.fetch(self.class::SCHEMA_NAME)['properties'][json])) }
      freeze
    end
    def self.wire_value(v)
      case v
      when Model then v.to_wire
      when Array then v.map { |x| wire_value(x) }
      when Hash then v.to_h { |k, x| [k.to_s.dup, wire_value(x)] }
      when String then v.dup
      else v
      end
    end
    def self.model_value(v, s)
      return nil if v.nil?
      return from_wire(v, s['$ref'].split('/').last) if s.key?('$ref')
      return v.map { |x| model_value(x, s['items']) }.freeze if v.is_a?(Array) && s.key?('items')
      v
    end
    def self.from_wire(v, name)
      klass = Models.const_get(name)
      inv = klass::FIELDS.invert
      klass.new(**v.to_h { |k, x| [inv.fetch(k).to_sym, x] })
    end
    def to_wire = @wire
    def inspect = "#<AvailKit::Models::#{self.class.name.split('::').last} (data redacted)>"
    alias to_s inspect
  end

  # Cooperative cancellation interrupts DNS/TLS/body via the bounded worker.
  # A cancellation after send is an UNKNOWN outcome. It never replays a request.
  class Cancellation
    def initialize
      @mutex = Mutex.new; @cancelled = false
    end
    def cancel = @mutex.synchronize { @cancelled = true }
    def cancelled? = @mutex.synchronize { @cancelled }
    def inspect = '#<AvailKit::Cancellation>'
  end
  def self.origin(value)
    u = URI.parse(value)
    fail_input('invalid_base_url') unless %w[https http].include?(u.scheme) && u.host && !u.userinfo && !u.query && !u.fragment && ['', '/'].include?(u.path) && value.ascii_only? && !value.match?(/[\x00-\x20\x7f]/) && (u.scheme == 'https' || %w[localhost 127.0.0.1 [::1]].include?(u.host)) && (1..65_535).cover?(u.port)
    value.delete_suffix('/')
  rescue URI::Error, ArgumentError, TypeError
    fail_input('invalid_base_url')
  end
  def self.read_private(path, limit)
    st = File.lstat(path)
    fail_input('invalid_private_file') unless st.file? && st.mode & 0o077 == 0 && st.uid == Process.uid && (1..limit).cover?(st.size)
    File.open(path, File::RDONLY | File::NONBLOCK | File::NOFOLLOW) do |f|
      fs = f.stat
      fail_input('invalid_private_file') unless fs.dev == st.dev && fs.ino == st.ino
      raw = f.read(limit + 1)
      fail_input('invalid_private_file') if raw.bytesize > limit
      raw
    end
  rescue Error
    raise
  rescue StandardError
    fail_input('invalid_private_file')
  end

  class Intent
    attr_reader :operation, :path, :body, :idempotency_key, :scope, :headers, :created_at
    def initialize(operation:, path:, body:, idempotency_key:, scope:, headers:, created_at: Time.now.utc.iso8601(6))
      AvailKit.fail_input('invalid_intent') unless [operation, path, body, scope, created_at].all? { |v| v.is_a?(String) } && body.bytesize <= 16_384 && headers.is_a?(Hash) && headers.all? { |k, v| k.is_a?(String) && v.is_a?(String) }
      AvailKit.key!(idempotency_key); AvailKit.instant(created_at)
      @operation, @path, @body, @idempotency_key, @scope, @headers, @created_at = [operation, path, body, idempotency_key, scope, headers, created_at].map { |v| AvailKit.freeze_value(Marshal.load(Marshal.dump(v))) }
      freeze
    rescue ArgumentError
      AvailKit.fail_input('invalid_intent_timestamp')
    end
    def inspect = '#<AvailKit::Intent (private)>'
    alias to_s inspect
    def save(path)
      st = File.lstat(File.dirname(path))
      AvailKit.fail_input('intent_persistence_failed') unless st.directory? && st.mode & 0o077 == 0 && st.uid == Process.uid
      raw = JSON.generate({version: 1, operation: operation, path: self.path, body: body, idempotencyKey: idempotency_key, scope: scope, headers: headers, createdAt: created_at})
      File.open(path, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o600) { |f| f.write(raw); f.flush; f.fsync }
      File.open(File.dirname(path), File::RDONLY) { |f| f.fsync }
      nil
    rescue StandardError
      AvailKit.fail_input('intent_persistence_failed')
    end
    def self.load(path)
      v = AvailKit.decode(AvailKit.read_private(path, 131_072))
      AvailKit.fail_input('invalid_intent_file') unless v.is_a?(Hash) && v.keys.sort == %w[version operation path body idempotencyKey scope headers createdAt].sort && v['version'] == 1
      new(operation: v['operation'], path: v['path'], body: v['body'], idempotency_key: v['idempotencyKey'], scope: v['scope'], headers: v['headers'], created_at: v['createdAt'])
    rescue StandardError
      AvailKit.fail_input('invalid_intent_file')
    end
  end

  class BaseClient
    def inspect = "#<AvailKit::#{self.class.name.split('::').last} (credentials redacted)>"
    alias to_s inspect
    def initialize_base(base_url, timeout, max_response_bytes)
      @origin = AvailKit.origin(base_url)
      AvailKit.fail_input('invalid_limits') unless timeout.is_a?(Numeric) && timeout > 0 && timeout <= 120 && max_response_bytes.is_a?(Integer) && (1..8_388_608).cover?(max_response_bytes)
      @timeout, @max_bytes = timeout.to_f, max_response_bytes
      @headers = {}
    end
    def with_request_options(cancellation: nil, timeout: nil)
      # Options belong to this synchronous block's thread, never shared client state.
      AvailKit.fail_input('invalid_options') unless cancellation.nil? || cancellation.is_a?(Cancellation)
      AvailKit.fail_input('invalid_limits') unless timeout.nil? || timeout.is_a?(Numeric) && timeout > 0 && timeout <= @timeout
      key = :"availkit_options_#{object_id}"; old = Thread.current[key]
      Thread.current[key] = {cancellation: cancellation, timeout: timeout}
      begin; yield self; ensure; Thread.current[key] = old; end
    end
    private
    def path_for(operation, ids)
      spec = OPERATIONS.fetch(operation)
      AvailKit.fail_input('invalid_operation') unless spec['path'].include?('/public/') == @public
      path = spec['path'].sub(%r!\A/v1/(?:workspaces|public/pages)/\{[^}]+\}!, '')
      ids.each do |id|
        AvailKit.identifier(id)
        AvailKit.fail_input('invalid_id') unless path.include?('{')
        path = path.sub(/\{[^}]+\}/, id)
      end
      AvailKit.fail_input('invalid_id') if path.include?('{')
      path
    end
    def page_query(after, limit, q = nil)
      AvailKit.fail_input('invalid_limit') unless limit.is_a?(Integer) && (1..100).cover?(limit)
      result = {'limit' => limit}
      result['after'] = AvailKit.identifier(after) unless after.nil?
      unless q.nil?
        AvailKit.fail_input('invalid_query') unless AvailKit.text?(q)
        result['q'] = q
      end
      result
    end
    def availability_query(id, from, to)
      AvailKit.identifier(id); a, b = AvailKit.instant(from), AvailKit.instant(to)
      AvailKit.fail_input('invalid_range') unless b > a && b - a <= 604_800
      {'offeringId' => id, 'from' => from, 'to' => to}
    rescue ArgumentError
      AvailKit.fail_input('invalid_range')
    end
    def event_query(after, limit)
      AvailKit.fail_input('invalid_query') unless after.is_a?(Integer) && (0..9_007_199_254_740_991).cover?(after) && limit.is_a?(Integer) && (1..100).cover?(limit)
      {'after' => after, 'limit' => limit}
    end
    def public_headers(booking, contact = nil)
      AvailKit.fail_input('invalid_guest_access') unless booking.is_a?(String) && TOKEN.match?(booking) && (contact.nil? || contact.is_a?(String) && TOKEN.match?(contact))
      h = {'Authorization' => 'Booking ' + booking}
      h['X-AvailKit-Contact-Token'] = contact unless contact.nil?
      h
    end
    def call(op, ids, body, query, headers)
      path = path_for(op, ids)
      path += '?' + URI.encode_www_form(query) unless query.empty?
      send_once(op, path, AvailKit.input_body(body, OPERATIONS.fetch(op)['input']), nil, headers)
    end
    def prepare(op, ids, body, key, headers)
      Intent.new(operation: op, path: path_for(op, ids), body: AvailKit.input_body(body, OPERATIONS.fetch(op)['input']), idempotency_key: AvailKit.key!(key), scope: @scope, headers: headers)
    end
    def send_once(op, path, body, key, headers)
      validate_headers!(op, headers)
      options = Thread.current[:"availkit_options_#{object_id}"] || {}
      cancellation = options[:cancellation]
      AvailKit.fail_input('cancelled') if cancellation&.cancelled?
      budget = options[:timeout] || @timeout
      result = nil
      # The worker owns socket resources. Interrupting it runs its ensure/finish;
      # join it before returning, so a timed-out worker can never send later.
      worker = Thread.new do
        Thread.current.report_on_exception = false
        http = nil
        begin
          Timeout.timeout(budget) do
            u = URI.parse(@origin)
            http = Net::HTTP.new(u.hostname, u.port, nil)
            http.max_retries = 0
            http.open_timeout = budget; http.read_timeout = budget; http.write_timeout = budget
            http.use_ssl = u.scheme == 'https'
            if http.use_ssl?
              http.verify_mode = OpenSSL::SSL::VERIFY_PEER
              http.verify_hostname = true
              http.min_version = OpenSSL::SSL::TLS1_2_VERSION
            end
            request = Net::HTTPGenericRequest.new(OPERATIONS.fetch(op)['method'], !body.nil?, true, @root + path, {'Accept' => 'application/json', 'Accept-Encoding' => 'identity', 'Cache-Control' => 'no-store', 'Connection' => 'close', 'User-Agent' => 'availkit-ruby/' + VERSION}.merge(@headers).merge(headers))
            request['Content-Type'] = 'application/json' unless body.nil?
            request['Idempotency-Key'] = key unless key.nil?
            request.body = body
            http.start do
              http.request(request) do |response|
                status = response.code.to_i
                media = response['content-type'].to_s.split(';').first.to_s.strip
                raise Error.new('protocol', 'invalid_response', status) if (300...400).cover?(status) || !%w[application/json application/problem+json].include?(media) || (200...300).cover?(status) && media != 'application/json' || ![nil, 'identity'].include?(response['content-encoding'])
                length = response['content-length']
                raise Error.new('protocol', 'response_too_large', status) if length && (!/\A\d+\z/.match?(length) || length.to_i > @max_bytes)
                raw = +''.b
                response.read_body do |chunk|
                  raw << chunk
                  raise Error.new('protocol', 'response_too_large', status) if raw.bytesize > @max_bytes
                end
                raise Error.new('protocol', 'incomplete_response', status) if length && raw.bytesize != length.to_i
                data = AvailKit.decode(raw)
                unless (200...300).cover?(status)
                  code = data.dig('error', 'code') if data.is_a?(Hash) && data['error'].is_a?(Hash) && data['error']['message'].is_a?(String)
                  code = data['code'] if data.is_a?(Hash) && data['type'] == 'urn:availkit:problem' && data['status'] == status
                  raise Error.new('protocol', 'invalid_error', status) unless code.is_a?(String)
                  raise Error.new('api', SAFE_CODES.include?(code) ? code : 'api_error', status)
                end
                spec = OPERATIONS.fetch(op)
                raise Error.new('protocol', 'invalid_response', status) unless status == spec['status'] && AvailKit.validate(data, spec['output']) && (!(@public || path.start_with?('/usage', '/maintenance/', '/customers')) || response['cache-control'] == 'no-store') && relations?(op, path, body, data)
                result = Model.from_wire(data, spec['output']['$ref'].split('/').last)
              end
            end
          end
        rescue Error => e
          result = e.kind == 'input' ? Error.new('protocol', 'invalid_response', e.status) : Error.new(e.kind, e.code, e.status)
        rescue Timeout::Error
          result = Error.new('transport', 'timeout')
        rescue JSON::ParserError
          result = Error.new('protocol', 'invalid_json')
        rescue StandardError
          result = Error.new('transport', 'request_failed')
        ensure
          begin; http.finish if http&.started?; rescue StandardError; end
        end
      end
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + budget
      while worker.alive?
        if cancellation&.cancelled? || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
          worker.kill; worker.join
          result = Error.new('transport', cancellation&.cancelled? ? 'cancelled' : 'timeout')
          break
        end
        worker.join([0.02, [deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC), 0].max].min)
      end
      worker.join
      raise(result, cause: nil) if result.is_a?(Error)
      raise(Error.new('transport', 'request_failed'), cause: nil) if result.nil?
      result
    ensure
      worker.kill.join if worker&.alive?
    end
    def validate_headers!(op, headers)
      expected = @public ? (op == 'bookPublic' ? %w[Authorization X-AvailKit-Contact-Token] : (%w[getPublicBooking cancelPublicBooking reschedulePublicBooking].include?(op) ? ['Authorization'] : [])) : []
      AvailKit.fail_input('invalid_intent') unless headers.keys.sort == expected.sort
      if expected.include?('Authorization')
        auth = headers['Authorization']; AvailKit.fail_input('invalid_guest_access') unless auth.start_with?('Booking ') && TOKEN.match?(auth.delete_prefix('Booking '))
      end
      AvailKit.fail_input('invalid_guest_access') if expected.include?('X-AvailKit-Contact-Token') && !TOKEN.match?(headers['X-AvailKit-Contact-Token'])
    end
    public
    # Explicit only. Never call automatically after unknown acknowledgement.
    def execute(intent)
      AvailKit.fail_input('intent_scope_mismatch') unless intent.is_a?(Intent) && intent.scope == @scope && REPLAY.include?(intent.operation)
      age = Time.now - AvailKit.instant(intent.created_at)
      AvailKit.fail_input('intent_expired') if age >= 86_400
      AvailKit.fail_input('invalid_intent_timestamp') if age < 0
      AvailKit.fail_input('invalid_intent') unless path_for(intent.operation, intent.path.scan(/[0-9a-f]{32}/)) == intent.path
      data = AvailKit.decode(intent.body)
      AvailKit.input_body(data, OPERATIONS.fetch(intent.operation)['input'])
      send_once(intent.operation, intent.path, intent.body, intent.idempotency_key, intent.headers)
    rescue JSON::ParserError
      AvailKit.fail_input('invalid_intent')
    end
  end
  class Client < BaseClient
    attr_reader :workspace_id, :environment
    def initialize(workspace_id:, environment:, credential: nil, credential_file: nil, base_url: 'https://api.availkit.com', timeout: 10, max_response_bytes: 1_048_576)
      @workspace_id = AvailKit.identifier(workspace_id).dup.freeze
      AvailKit.fail_input('invalid_environment') unless %w[test live].include?(environment)
      @environment = environment.freeze
      AvailKit.fail_input('ambiguous_credential') unless credential.nil? != credential_file.nil?
      credential = AvailKit.read_private(credential_file, 4096).delete_suffix("\n").delete_suffix("\r") unless credential_file.nil?
      AvailKit.fail_input('invalid_credential') unless credential.is_a?(String) && TOKEN.match?(credential)
      @public = false; initialize_base(base_url, timeout, max_response_bytes)
      @root = '/v1/workspaces/' + workspace_id
      @scope = @origin + ':' + workspace_id + ':' + environment + ':' + Digest::SHA256.hexdigest(credential)
      @headers = {'Authorization' => 'Bearer ' + credential}
    end
  end
  class PublicClient < BaseClient
    attr_reader :page_id
    def initialize(page_id:, base_url: 'https://api.availkit.com', timeout: 2, max_response_bytes: 262_144)
      @page_id = AvailKit.identifier(page_id).dup.freeze; @public = true
      initialize_base(base_url, timeout, max_response_bytes)
      @root = '/v1/public/pages/' + page_id; @scope = @origin + ':public:' + page_id
    end
  end
  def self.verify_webhook(body, signature, secret, now: Time.now.to_i, tolerance: 300)
    fail_input('invalid_webhook_tolerance') unless now.is_a?(Integer) && now >= 0 && tolerance.is_a?(Integer) && (0..3600).cover?(tolerance)
    return false unless body.is_a?(String) && body.bytesize <= 16_384 && signature.is_a?(String) && secret.is_a?(String) && TOKEN.match?(secret)
    m = /\At=(0|[1-9][0-9]{0,19}),v1=([0-9a-f]{64})\z/.match(signature)
    return false unless m && (now - m[1].to_i).abs <= tolerance
    expected = OpenSSL::HMAC.hexdigest('SHA256', Base64.urlsafe_decode64(secret + '='), m[1] + '.' + body)
    OpenSSL.fixed_length_secure_compare(expected, m[2])
  rescue ArgumentError
    false
  end
end
AvailKit.freeze_value(AvailKit::SCHEMAS)
AvailKit.freeze_value(AvailKit::OPERATIONS)
require_relative 'availkit/models'
require_relative 'availkit/relations'
require_relative 'availkit/operations'
