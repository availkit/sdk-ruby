# AvailKit Ruby SDK 0.1.1

SDK **0.1.1**. Standalone build and synthetic test instructions are in
[DEVELOPMENT.md](DEVELOPMENT.md). [Versioned release notes](https://github.com/availkit/sdk-ruby/releases)
record dated verification and available distribution channels. Source availability
does not imply registry publication or mobile/service acceptance.
Install examples name this SDK version; check the release notes for artifact availability.

Trusted server-side workspace integrations and a separate public booking client. Supported Ruby3.3,3.4and4.0; stdlib/default gems only (json,net-http,openssl,base64,logger where supplied by the Ruby distribution). Actual testedversions are in `runtime-policy.json` and release acceptance. No account/passkey/session/recovery API is invented. No workspace credential belongs in a browser/mobile app.

## Install hosted gem without a private checkout

<!-- docs:install:start -->
```sh
curl --fail --proto '=https' -O https://availkit.dev/downloads/availkit-0.1.1.gem
curl --fail --proto '=https' -O https://availkit.dev/downloads/SHA256SUMS
sha256sum --check --ignore-missing SHA256SUMS
gem install --local ./availkit-0.1.1.gem --no-document
ruby -ravailkit -e 'puts AvailKit::VERSION'
```
<!-- docs:install:end -->

This is a normal standalone gem with models, schemas, full source, tests and runnable examples. RubyGems.org availability/ownership is not claimed. For a clean isolated installation use `gem install --local ... --install-dir /absolute/private/gems` and set GEM_HOME/GEM_PATH to it plus your runtime's bundled/default gem paths.

```ruby
require 'availkit'
client = AvailKit::Client.new(workspace_id: workspace_id, environment: 'test', credential_file: '/absolute/private/test-key', timeout: 10)
page = client.list_offerings(limit: 25)
page.items.each { |offering| puts offering.name }
```

## Complete runnable lifecycle

Provide an owned test workspace/offering with at least two available slots. Use a Read+Book test key; linking an existing customer adds Manage. Catalog editing requires Edit catalog; customer/webhook management requires Manage; erasure/history maintenance requires Manage+Privacy; expired replay pruning requires Privacy. Keys bind their actual environment on the server. The explicit environment argument records caller intent and cannot change a key's authority.

Use a secure editor to put the raw key in an owner-only0600file. Never pass it as a command argument. Prepare a0700directory and non-secret environment settings:

<!-- docs:run:start -->
```sh
umask 077
mkdir -m 700 ./private-intents
export AVAILKIT_CREDENTIAL_FILE=/absolute/private/test-key
export AVAILKIT_INTENT_DIR=/absolute/private/private-intents
export AVAILKIT_WORKSPACE_ID=YOUR_32_HEX_WORKSPACE_ID
export AVAILKIT_ENVIRONMENT=test
export AVAILKIT_OFFERING_ID=YOUR_32_HEX_OFFERING_ID
export AVAILKIT_FROM=2030-01-07T00:00:00Z
export AVAILKIT_TO=2030-01-08T00:00:00Z
ruby "$(ruby -e 'puts Gem::Specification.find_by_name("availkit").full_gem_path')/examples/first-booking.rb"
```
<!-- docs:run:end -->

The examples default to `https://api.availkit.com`. For an explicitly controlled loopback verification proxy or a deliberately configured self-hosted endpoint, optionally set `AVAILKIT_BASE_URL` before running; for example, `export AVAILKIT_BASE_URL=http://127.0.0.1:18701`. This uses the existing SDK origin policy: HTTPS still validates certificates and hostnames, plain HTTP remains limited to literal loopback, and retained intents remain bound to the exact configured origin. Leave it unset for the canonical service.

Choose real future UTC values; the half-open range cannot exceed seven days. The runnable example discovers times, saves original create intent before the send, reads the acknowledged booking, moves it with expectedStart, then cancels it. All intent files are exclusive0600, fsynced and never overwritten. Any failure stops the whole sequence. It creates no catalog/fixture data or unrelated cleanup.

The packaged `examples/public-booking.rb` uses `AVAILKIT_PAGE_ID`, `AVAILKIT_CONTACT_NAME`, offering/range and private intent directory. It accepts no workspace key/cookie, requires a test page and creates booking capability+contact proof before the send. Private create/move/cancel intent files retain original tokens and exact bodies. After an unknown creation without an acknowledged booking ID, stop: the capability cannot discover the ID. Keep the intent and reconcile with the owner.

## Types, validation and bounded transport

`AvailKit::Models` provides immutable keyword request and response classes (`ResourceInput.new(name:, time_zone:, capacity:)`, `BookingInput.new(offering_id:, start:)`, `RescheduleInput.new(expected_start:, start:)`, etc.). Explicit null is preserved separately from absent optional keywords. Response pages contain typed item models and `next_after`; paginate explicitly with a bounded application loop. Wire hashes with exact JSON camelCase keys are also accepted as request bodies. UTC RFC3339 strings retain input precision. All34workspace+7public wrappers appear in `coverage.json`.

Runtime validation enforces required fields, unions/nullability, unknown members, bounded schema values plus name/contact/hours rules and response/cursor/booking/usage relations. Availability and permission decisions remain server-authoritative. Net::HTTP max_retries=0 suppresses its built-in retry behavior; SDK never retries. New direct connections ignore proxy environment, follow no redirects, send no cookies and request identity encoding. TLS checks hostnames and certificates (minimumTLS1.2). HTTP is accepted only for literal loopback test origins.

Timeout is an absolute DNS-through-body wall-clock budget (default10s workspace/2s public, max120s), enforced by a joined worker owning and closing its connection. JSON is bounded (default1MiB workspace/256KiB public; maximum8MiB), duplicate keys/invalid UTF-8/NaN/trailing values rejected. Per-call cancellation and shorter timeout:

```ruby
cancel = AvailKit::Cancellation.new
client.with_request_options(cancellation: cancel, timeout: 2) { |c| c.list_bookings }
# Another thread may call cancel.cancel; pre-cancelled requests are not sent.
```

Cancellation after sending has unknown outcome. Worker cleanup is joined before returning. Request options are thread-local to the block and restored even on errors; clients do not mutate shared options.

## Original intent and uncertainty

```ruby
intent = client.prepare_book(AvailKit::Models::BookingInput.new(offering_id: offering_id, start: start), idempotency_key: AvailKit.new_idempotency_key)
intent.save('/absolute/owned-0700-dir/create.json') # must succeed BEFORE send
booking = client.execute(intent)
```

`AvailKit::Error` exposes only kind, code, status, outcome (`not_sent`,`rejected`,`unknown`); its message and inspect contain no server text, raw causes, URLs, tokens or bodies. Intent/client/model inspection is redacted. Debuggers that capture local variables still see caller data; log `error.to_h` only. Explicit `to_wire` intentionally exposes business/once-only signing-secret values to the caller for private persistence.

Keep retained intent after timeout/disconnect/503/malformed success. Loading `AvailKit::Intent.load(path)` never sends; explicit `execute` uses exact body/key/original authority. Only book/cancel/reschedule have an explicit server24h replay contract. Local age validation cannot establish that the receipt survived privacy pruning or that current authority still permits replay. Never generate a new key/body for an uncertain original intent. Catalog/customer/webhook/maintenance writes have no replay guarantee. Reads do not settle a lost mutation acknowledgement.

Private-file helpers require POSIX uid/modes, reject symlinks/nonregular files and verify opened inode. On other platforms supply `credential:` from a platform secret store and implement equivalent durable intent storage; do not weaken private-file permissions.

## Webhook verification

```ruby
verified = AvailKit.verify_webhook(raw_body, signature_header, signing_secret, tolerance: 300)
```

Verify exact raw body BEFORE JSON decoding. Then transactionally deduplicate stable `AvailKit-Delivery-ID` together with the durable domain update before returning2xx. Retried deliveries retain identity and refresh signature timestamp. `examples/webhook.rb` is a runnable loopback-only raw HTTP verification endpoint; it demonstrates verification, not durable business processing.

## Verify and package

```sh
ruby -Ilib test/sdk_test.rb
ruby build.rb /absolute/output
python3 test/package_test.py
```

Tests exercise all41wrappers over actual loopback HTTP, retained unknown response/send-once, exact original replay, scope isolation, malformed/denied responses, bounded deadline/cancellation, private-file protections and raw-body HMAC tampering. Authenticated/hosted clean-consumer results belong to release acceptance. Artifact is `availkit-0.1.1.gem`; no build service or native extension is required.


See [CHANGELOG.md](CHANGELOG.md), [SUPPORT.md](SUPPORT.md) and
[SECURITY.md](SECURITY.md) for release policy and private reporting prerequisites.
`contract-projection.json` pins only this SDK's supported wire operations;
additive unrelated API routes do not imply this SDK implements them.

The separate optional business export endpoint and current versioned browser
recovery protocol are not methods of this SDK. Use their documented browser/
TypeScript integration where appropriate; this package preserves its declared
workspace/public booking surface rather than inventing account/native APIs.
