# frozen_string_literal: true
require 'availkit'
# docs:configuration:start
abort 'Example requires AVAILKIT_ENVIRONMENT=test' unless ENV['AVAILKIT_ENVIRONMENT'] == 'test'
client = AvailKit::Client.new(base_url: ENV.fetch('AVAILKIT_BASE_URL', 'https://api.availkit.com'), workspace_id: ENV.fetch('AVAILKIT_WORKSPACE_ID'), environment: ENV.fetch('AVAILKIT_ENVIRONMENT'), credential_file: ENV.fetch('AVAILKIT_CREDENTIAL_FILE'), timeout: 10)
# docs:configuration:end
begin
  dir = ENV.fetch('AVAILKIT_INTENT_DIR')
  # docs:lifecycle:start
  availability = client.availability(offering_id: ENV.fetch('AVAILKIT_OFFERING_ID'), from: ENV.fetch('AVAILKIT_FROM'), to: ENV.fetch('AVAILKIT_TO'))
  abort 'Need two distinct available times' if availability.slots.length < 2
  create = client.prepare_book(AvailKit::Models::BookingInput.new(offering_id: ENV.fetch('AVAILKIT_OFFERING_ID'), start: availability.slots[0]['start']), idempotency_key: AvailKit.new_idempotency_key)
  create.save(File.join(dir, 'create.json')) # Persist privately BEFORE send.
  booking = client.execute(create) # Any unknown stops; no automatic resend.
  booking = client.get_booking(booking.id)
  move = client.prepare_reschedule(booking.id, AvailKit::Models::RescheduleInput.new(expected_start: booking.start, start: availability.slots[1]['start']), idempotency_key: AvailKit.new_idempotency_key)
  move.save(File.join(dir, 'move.json'))
  booking = client.execute(move)
  cancel = client.prepare_cancel(booking.id, idempotency_key: AvailKit.new_idempotency_key)
  cancel.save(File.join(dir, 'cancel.json'))
  booking = client.execute(cancel)
  # docs:lifecycle:end
  puts JSON.generate({booking_id: booking.id, status: booking.status})
rescue AvailKit::Error => e
  warn JSON.generate(e.to_h)
  abort 'Stopped. Retain private intent files; inspect outcome before deciding on explicit replay.'
end
