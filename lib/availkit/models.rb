# frozen_string_literal: true
module AvailKit
  module Models
    class ResourceInput < Model
      SCHEMA_NAME = "ResourceInput"
      FIELDS = {"name" => "name", "time_zone" => "timeZone", "capacity" => "capacity"}.freeze
      attr_reader :name, :time_zone, :capacity
    end
    class Resource < Model
      SCHEMA_NAME = "Resource"
      FIELDS = {"id" => "id", "name" => "name", "time_zone" => "timeZone", "capacity" => "capacity", "archived" => "archived"}.freeze
      attr_reader :id, :name, :time_zone, :capacity, :archived
    end
    class ResourcePage < Model
      SCHEMA_NAME = "ResourcePage"
      FIELDS = {"items" => "items", "next_after" => "nextAfter"}.freeze
      attr_reader :items, :next_after
    end
    class Hours < Model
      SCHEMA_NAME = "Hours"
      FIELDS = {"windows" => "windows"}.freeze
      attr_reader :windows
    end
    class OfferingInput < Model
      SCHEMA_NAME = "OfferingInput"
      FIELDS = {"name" => "name", "resource_id" => "resourceId", "duration_minutes" => "durationMinutes"}.freeze
      attr_reader :name, :resource_id, :duration_minutes
    end
    class Offering < Model
      SCHEMA_NAME = "Offering"
      FIELDS = {"id" => "id", "name" => "name", "resource_id" => "resourceId", "duration_minutes" => "durationMinutes", "archived" => "archived"}.freeze
      attr_reader :id, :name, :resource_id, :duration_minutes, :archived
    end
    class OfferingPage < Model
      SCHEMA_NAME = "OfferingPage"
      FIELDS = {"items" => "items", "next_after" => "nextAfter"}.freeze
      attr_reader :items, :next_after
    end
    class Availability < Model
      SCHEMA_NAME = "Availability"
      FIELDS = {"slots" => "slots"}.freeze
      attr_reader :slots
    end
    class BookingInput < Model
      SCHEMA_NAME = "BookingInput"
      FIELDS = {"offering_id" => "offeringId", "start" => "start", "customer_id" => "customerId"}.freeze
      attr_reader :offering_id, :start, :customer_id
    end
    class Booking < Model
      SCHEMA_NAME = "Booking"
      FIELDS = {"id" => "id", "offering_id" => "offeringId", "resource_id" => "resourceId", "start" => "start", "end" => "end", "status" => "status", "customer_id" => "customerId"}.freeze
      attr_reader :id, :offering_id, :resource_id, :start, :end, :status, :customer_id
    end
    class BookingPage < Model
      SCHEMA_NAME = "BookingPage"
      FIELDS = {"items" => "items", "next_after" => "nextAfter"}.freeze
      attr_reader :items, :next_after
    end
    class Events < Model
      SCHEMA_NAME = "Events"
      FIELDS = {"events" => "events", "next_after" => "nextAfter", "retention_floor" => "retentionFloor", "high_water" => "highWater"}.freeze
      attr_reader :events, :next_after, :retention_floor, :high_water
    end
    class WebhookCreate < Model
      SCHEMA_NAME = "WebhookCreate"
      FIELDS = {"url" => "url"}.freeze
      attr_reader :url
    end
    class WebhookCreated < Model
      SCHEMA_NAME = "WebhookCreated"
      FIELDS = {"id" => "id", "url" => "url", "enabled" => "enabled", "created_at" => "createdAt", "signing_secret" => "signingSecret"}.freeze
      attr_reader :id, :url, :enabled, :created_at, :signing_secret
    end
    class WebhookPage < Model
      SCHEMA_NAME = "WebhookPage"
      FIELDS = {"items" => "items", "next_after" => "nextAfter"}.freeze
      attr_reader :items, :next_after
    end
    class Webhook < Model
      SCHEMA_NAME = "Webhook"
      FIELDS = {"id" => "id", "url" => "url", "enabled" => "enabled", "created_at" => "createdAt"}.freeze
      attr_reader :id, :url, :enabled, :created_at
    end
    class WebhookDisable < Model
      SCHEMA_NAME = "WebhookDisable"
      FIELDS = {}.freeze
    end
    class WebhookDeliveryPage < Model
      SCHEMA_NAME = "WebhookDeliveryPage"
      FIELDS = {"items" => "items", "next_after" => "nextAfter"}.freeze
      attr_reader :items, :next_after
    end
    class WebhookDelivery < Model
      SCHEMA_NAME = "WebhookDelivery"
      FIELDS = {"id" => "id", "subscription_id" => "subscriptionId", "event_id" => "eventId", "state" => "state", "created_at" => "createdAt", "attempts" => "attempts", "max_attempts" => "maxAttempts", "next_attempt_at" => "nextAttemptAt", "lease_expires_at" => "leaseExpiresAt", "last_attempt_at" => "lastAttemptAt", "last_outcome" => "lastOutcome", "last_http_status" => "lastHttpStatus"}.freeze
      attr_reader :id, :subscription_id, :event_id, :state, :created_at, :attempts, :max_attempts, :next_attempt_at, :lease_expires_at, :last_attempt_at, :last_outcome, :last_http_status
    end
    class Usage < Model
      SCHEMA_NAME = "Usage"
      FIELDS = {"as_of" => "asOf", "period" => "period", "counters" => "counters"}.freeze
      attr_reader :as_of, :period, :counters
    end
    class UsagePeriod < Model
      SCHEMA_NAME = "UsagePeriod"
      FIELDS = {"start" => "start", "end" => "end"}.freeze
      attr_reader :start, :end
    end
    class UsageCounters < Model
      SCHEMA_NAME = "UsageCounters"
      FIELDS = {"monthly_booking_creates" => "monthlyBookingCreates", "catalog_objects" => "catalogObjects", "booking_records" => "bookingRecords", "committed_events" => "committedEvents", "webhook_subscriptions" => "webhookSubscriptions", "webhook_deliveries" => "webhookDeliveries", "live_replays" => "liveReplays", "customer_records" => "customerRecords"}.freeze
      attr_reader :monthly_booking_creates, :catalog_objects, :booking_records, :committed_events, :webhook_subscriptions, :webhook_deliveries, :live_replays, :customer_records
    end
    class UsageCounter < Model
      SCHEMA_NAME = "UsageCounter"
      FIELDS = {"used" => "used", "limit" => "limit", "remaining" => "remaining"}.freeze
      attr_reader :used, :limit, :remaining
    end
    class RescheduleInput < Model
      SCHEMA_NAME = "RescheduleInput"
      FIELDS = {"expected_start" => "expectedStart", "start" => "start"}.freeze
      attr_reader :expected_start, :start
    end
    class HistoryPruneInput < Model
      SCHEMA_NAME = "HistoryPruneInput"
      FIELDS = {"kind" => "kind", "limit" => "limit"}.freeze
      attr_reader :kind, :limit
    end
    class HistoryPruneResult < Model
      SCHEMA_NAME = "HistoryPruneResult"
      FIELDS = {"as_of" => "asOf", "cutoff" => "cutoff", "deleted" => "deleted", "has_more" => "hasMore"}.freeze
      attr_reader :as_of, :cutoff, :deleted, :has_more
    end
    class CustomerInput < Model
      SCHEMA_NAME = "CustomerInput"
      FIELDS = {"display_name" => "displayName", "email" => "email", "phone" => "phone"}.freeze
      attr_reader :display_name, :email, :phone
    end
    class Customer < Model
      SCHEMA_NAME = "Customer"
      FIELDS = {"id" => "id", "display_name" => "displayName", "email" => "email", "phone" => "phone", "archived" => "archived", "erased" => "erased"}.freeze
      attr_reader :id, :display_name, :email, :phone, :archived, :erased
    end
    class CustomerPage < Model
      SCHEMA_NAME = "CustomerPage"
      FIELDS = {"items" => "items", "next_after" => "nextAfter"}.freeze
      attr_reader :items, :next_after
    end
    class Empty < Model
      SCHEMA_NAME = "Empty"
      FIELDS = {}.freeze
    end
    class CustomerErased < Model
      SCHEMA_NAME = "CustomerErased"
      FIELDS = {"id" => "id", "erased" => "erased"}.freeze
      attr_reader :id, :erased
    end
    class MaintenanceInput < Model
      SCHEMA_NAME = "MaintenanceInput"
      FIELDS = {"limit" => "limit"}.freeze
      attr_reader :limit
    end
    class MaintenanceResult < Model
      SCHEMA_NAME = "MaintenanceResult"
      FIELDS = {"as_of" => "asOf", "deleted" => "deleted", "has_more" => "hasMore"}.freeze
      attr_reader :as_of, :deleted, :has_more
    end
    class PublicPage < Model
      SCHEMA_NAME = "PublicPage"
      FIELDS = {"id" => "id", "title" => "title", "environment" => "environment", "email_notifications" => "emailNotifications"}.freeze
      attr_reader :id, :title, :environment, :email_notifications
    end
    class PublicOfferingPage < Model
      SCHEMA_NAME = "PublicOfferingPage"
      FIELDS = {"items" => "items", "next_after" => "nextAfter"}.freeze
      attr_reader :items, :next_after
    end
    class PublicOffering < Model
      SCHEMA_NAME = "PublicOffering"
      FIELDS = {"id" => "id", "name" => "name", "duration_minutes" => "durationMinutes", "time_zone" => "timeZone"}.freeze
      attr_reader :id, :name, :duration_minutes, :time_zone
    end
    class PublicBookingInput < Model
      SCHEMA_NAME = "PublicBookingInput"
      FIELDS = {"offering_id" => "offeringId", "start" => "start", "contact" => "contact"}.freeze
      attr_reader :offering_id, :start, :contact
    end
    class PublicBooking < Model
      SCHEMA_NAME = "PublicBooking"
      FIELDS = {"id" => "id", "start" => "start", "end" => "end", "status" => "status", "offering" => "offering", "page" => "page", "page_enabled" => "pageEnabled"}.freeze
      attr_reader :id, :start, :end, :status, :offering, :page, :page_enabled
    end
    class BookingPageSettings < Model
      SCHEMA_NAME = "BookingPageSettings"
      FIELDS = {"page_id" => "pageId", "title" => "title", "enabled" => "enabled", "needs_republish" => "needsRepublish"}.freeze
      attr_reader :page_id, :title, :enabled, :needs_republish
    end
    class BookingPageInput < Model
      SCHEMA_NAME = "BookingPageInput"
      FIELDS = {"title" => "title", "enabled" => "enabled"}.freeze
      attr_reader :title, :enabled
    end
    class HoursWindowsItem < Model
      SCHEMA_NAME = "HoursWindowsItem"
      FIELDS = {"weekday" => "weekday", "start" => "start", "end" => "end"}.freeze
      attr_reader :weekday, :start, :end
    end
    class AvailabilitySlotsItem < Model
      SCHEMA_NAME = "AvailabilitySlotsItem"
      FIELDS = {"start" => "start", "end" => "end", "remaining_capacity" => "remainingCapacity"}.freeze
      attr_reader :start, :end, :remaining_capacity
    end
    class EventsEventsItem < Model
      SCHEMA_NAME = "EventsEventsItem"
      FIELDS = {"id" => "id", "sequence" => "sequence", "type" => "type", "booking_id" => "bookingId", "occurred_at" => "occurredAt"}.freeze
      attr_reader :id, :sequence, :type, :booking_id, :occurred_at
    end
  end
end
