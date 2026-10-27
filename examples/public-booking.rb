# frozen_string_literal: true
require 'availkit'
begin
  client = AvailKit::PublicClient.new(base_url: ENV.fetch('AVAILKIT_BASE_URL', 'https://api.availkit.com'), page_id: ENV.fetch('AVAILKIT_PAGE_ID'))
  abort 'Example requires a test page' unless client.get_page.environment == 'test'
  times = client.availability(offering_id: ENV.fetch('AVAILKIT_OFFERING_ID'), from: ENV.fetch('AVAILKIT_FROM'), to: ENV.fetch('AVAILKIT_TO')).slots
  abort 'Need two distinct available times' if times.length < 2
  booking_token, contact_token = AvailKit.new_guest_token, AvailKit.new_guest_token
  create = client.prepare_book(AvailKit::Models::PublicBookingInput.new(offering_id: ENV.fetch('AVAILKIT_OFFERING_ID'), start: times[0]['start'], contact: AvailKit::Models::CustomerInput.new(display_name: ENV.fetch('AVAILKIT_CONTACT_NAME'))), idempotency_key: AvailKit.new_idempotency_key, booking_token: booking_token, contact_token: contact_token)
  dir = ENV.fetch('AVAILKIT_INTENT_DIR'); create.save(File.join(dir, 'public-create.json'))
  booking = client.execute(create) # Unknown create has no discoverable ID: stop.
  booking = client.get_booking(booking.id, booking_token: booking_token)
  move = client.prepare_reschedule(booking.id, AvailKit::Models::RescheduleInput.new(expected_start: booking.start, start: times[1]['start']), idempotency_key: AvailKit.new_idempotency_key, booking_token: booking_token)
  move.save(File.join(dir, 'public-move.json')); booking = client.execute(move)
  cancel = client.prepare_cancel(booking.id, idempotency_key: AvailKit.new_idempotency_key, booking_token: booking_token)
  cancel.save(File.join(dir, 'public-cancel.json')); booking = client.execute(cancel)
  puts 'Public booking lifecycle acknowledged; status=' + booking.status
rescue AvailKit::Error => e
  warn JSON.generate(e.to_h); abort 'Stopped; retain private intent/capabilities. Never generate a new key for an unknown intent.'
end
