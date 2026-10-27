# frozen_string_literal: true
module AvailKit
  class Client
    def create_resource(body)
      call("createResource", [], body, {}, {})
    end
  end
  class Client
    def list_resources(after: nil, limit: 25, q: nil)
      call("listResources", [], nil, page_query(after, limit, q), {})
    end
  end
  class Client
    def replace_hours(resource_id, body)
      call("setHours", [resource_id], body, {}, {})
    end
  end
  class Client
    def get_hours(resource_id)
      call("getHours", [resource_id], nil, {}, {})
    end
  end
  class Client
    def create_offering(body)
      call("createOffering", [], body, {}, {})
    end
  end
  class Client
    def list_offerings(after: nil, limit: 25, q: nil)
      call("listOfferings", [], nil, page_query(after, limit, q), {})
    end
  end
  class Client
    def availability(offering_id:, from:, to:)
      call("availability", [], nil, availability_query(offering_id, from, to), {})
    end
  end
  class Client
    def book(body, idempotency_key:)
      execute(prepare_book(body, idempotency_key: idempotency_key))
    end
    def prepare_book(body, idempotency_key:)
      prepare("book", [], body, idempotency_key, {})
    end
  end
  class Client
    def list_bookings(after: nil, limit: 25)
      call("listBookings", [], nil, page_query(after, limit), {})
    end
  end
  class Client
    def cancel(booking_id, idempotency_key:)
      execute(prepare_cancel(booking_id, idempotency_key: idempotency_key))
    end
    def prepare_cancel(booking_id, idempotency_key:)
      prepare("cancel", [booking_id], {}, idempotency_key, {})
    end
  end
  class Client
    def events(after: 0, limit: 100)
      call("events", [], nil, event_query(after, limit), {})
    end
  end
  class Client
    def get_resource(resource_id)
      call("getResource", [resource_id], nil, {}, {})
    end
  end
  class Client
    def replace_resource(resource_id, body)
      call("updateResource", [resource_id], body, {}, {})
    end
  end
  class Client
    def get_offering(offering_id)
      call("getOffering", [offering_id], nil, {}, {})
    end
  end
  class Client
    def replace_offering(offering_id, body)
      call("updateOffering", [offering_id], body, {}, {})
    end
  end
  class Client
    def get_booking(booking_id)
      call("getBooking", [booking_id], nil, {}, {})
    end
  end
  class Client
    def create_webhook(body)
      call("createWebhook", [], body, {}, {})
    end
  end
  class Client
    def list_webhooks(after: nil, limit: 25)
      call("listWebhooks", [], nil, page_query(after, limit), {})
    end
  end
  class Client
    def disable_webhook(subscription_id)
      call("disableWebhook", [subscription_id], {}, {}, {})
    end
  end
  class Client
    def list_webhook_deliveries(subscription_id, after: nil, limit: 25)
      call("listWebhookDeliveries", [subscription_id], nil, page_query(after, limit), {})
    end
  end
  class Client
    def get_usage()
      call("getUsage", [], nil, {}, {})
    end
  end
  class Client
    def reschedule_booking(booking_id, body, idempotency_key:)
      execute(prepare_reschedule(booking_id, body, idempotency_key: idempotency_key))
    end
    def prepare_reschedule(booking_id, body, idempotency_key:)
      prepare("rescheduleBooking", [booking_id], body, idempotency_key, {})
    end
  end
  class Client
    def archive_resource(resource_id)
      call("archiveResource", [resource_id], {}, {}, {})
    end
  end
  class Client
    def archive_offering(offering_id)
      call("archiveOffering", [offering_id], {}, {}, {})
    end
  end
  class Client
    def prune_history(body)
      call("pruneHistory", [], body, {}, {})
    end
  end
  class Client
    def create_customer(body)
      call("createCustomer", [], body, {}, {})
    end
  end
  class Client
    def list_customers(after: nil, limit: 25, q: nil)
      call("listCustomers", [], nil, page_query(after, limit, q), {})
    end
  end
  class Client
    def get_customer(customer_id)
      call("getCustomer", [customer_id], nil, {}, {})
    end
  end
  class Client
    def replace_customer(customer_id, body)
      call("replaceCustomer", [customer_id], body, {}, {})
    end
  end
  class Client
    def archive_customer(customer_id)
      call("archiveCustomer", [customer_id], {}, {}, {})
    end
  end
  class Client
    def erase_customer(customer_id)
      call("eraseCustomer", [customer_id], {}, {}, {})
    end
  end
  class Client
    def prune_expired_replays(body)
      call("pruneExpiredReplays", [], body, {}, {})
    end
  end
  class PublicClient
    def get_page()
      call("getPublicPage", [], nil, {}, {})
    end
  end
  class PublicClient
    def list_offerings(after: nil, limit: 25)
      call("listPublicOfferings", [], nil, page_query(after, limit), {})
    end
  end
  class PublicClient
    def availability(offering_id:, from:, to:)
      call("publicAvailability", [], nil, availability_query(offering_id, from, to), {})
    end
  end
  class PublicClient
    def book(body, booking_token:, contact_token:, idempotency_key:)
      execute(prepare_book(body, booking_token: booking_token, contact_token: contact_token, idempotency_key: idempotency_key))
    end
    def prepare_book(body, booking_token:, contact_token:, idempotency_key:)
      prepare("bookPublic", [], body, idempotency_key, public_headers(booking_token, contact_token))
    end
  end
  class PublicClient
    def get_booking(booking_id, booking_token:)
      call("getPublicBooking", [booking_id], nil, {}, public_headers(booking_token))
    end
  end
  class PublicClient
    def cancel(booking_id, booking_token:, idempotency_key:)
      execute(prepare_cancel(booking_id, booking_token: booking_token, idempotency_key: idempotency_key))
    end
    def prepare_cancel(booking_id, booking_token:, idempotency_key:)
      prepare("cancelPublicBooking", [booking_id], {}, idempotency_key, public_headers(booking_token))
    end
  end
  class PublicClient
    def reschedule(booking_id, body, booking_token:, idempotency_key:)
      execute(prepare_reschedule(booking_id, body, booking_token: booking_token, idempotency_key: idempotency_key))
    end
    def prepare_reschedule(booking_id, body, booking_token:, idempotency_key:)
      prepare("reschedulePublicBooking", [booking_id], body, idempotency_key, public_headers(booking_token))
    end
  end
  class Client
    def get_booking_page()
      call("getBookingPage", [], nil, {}, {})
    end
  end
  class Client
    def replace_booking_page(body)
      call("replaceBookingPage", [], body, {}, {})
    end
  end
end
