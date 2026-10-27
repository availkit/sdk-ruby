# frozen_string_literal: true
module AvailKit
  class BaseClient
    private
    def relations?(op, path, raw, data)
      body = raw ? AvailKit.decode(raw) : nil
      url = URI.parse(path); query = URI.decode_www_form(url.query || '').to_h
      parts = url.path.split('/')
      AvailKit.semantic_input!(data, {'$ref' => '#/components/schemas/Hours'}) if %w[getHours setHours].include?(op)
      if data.key?('items')
        items = data['items']; limit = query.fetch('limit', '25').to_i; previous = query.fetch('after', '')
        return false if items.length > limit
        items.each do |item|
          return false unless item['id'].is_a?(String) && ID.match?(item['id']) && item['id'] > previous
          previous = item['id']
          return false if op == 'listWebhookDeliveries' && item['subscriptionId'] != parts[2]
        end
        return false unless data['nextAfter'].nil? || items.length == limit && data['nextAfter'] == previous
      end
      return false if %w[getResource updateResource archiveResource getOffering updateOffering archiveOffering getBooking cancel rescheduleBooking getCustomer replaceCustomer archiveCustomer eraseCustomer disableWebhook getPublicBooking cancelPublicBooking reschedulePublicBooking].include?(op) && data['id'] != parts[2]
      return false if %w[book getBooking cancel rescheduleBooking getPublicBooking bookPublic cancelPublicBooking reschedulePublicBooking].include?(op) && AvailKit.instant(data['end']) <= AvailKit.instant(data['start'])
      return false if %w[cancel cancelPublicBooking].include?(op) && data['status'] != 'cancelled'
      return false if %w[book bookPublic rescheduleBooking reschedulePublicBooking].include?(op) && (data['status'] != 'confirmed' || AvailKit.instant(data['start']) != AvailKit.instant(body['start']))
      return false if op == 'book' && (data['offeringId'] != body['offeringId'] || data['customerId'] != body['customerId'])
      return false if op == 'bookPublic' && data['offering']['id'] != body['offeringId']
      return false if %w[archiveResource archiveOffering archiveCustomer].include?(op) && data['archived'] != true
      return false if op == 'disableWebhook' && data['enabled'] != false
      return false if @public && (op == 'getPublicPage' && data['id'] != @page_id || data.key?('page') && data['page']['id'] != @page_id)
      if %w[availability publicAvailability].include?(op)
        lo, hi = AvailKit.instant(query['from']), AvailKit.instant(query['to']); previous = nil
        data['slots'].each do |slot|
          a, b = AvailKit.instant(slot['start']), AvailKit.instant(slot['end'])
          return false unless a >= lo && b > a && b <= hi && slot['remainingCapacity'] > 0 && (previous.nil? || a > previous)
          previous = a
        end
      end
      if op == 'getUsage'
        t = AvailKit.instant(data['asOf']); start = Time.utc(t.year, t.month, 1); finish = t.month == 12 ? Time.utc(t.year + 1, 1, 1) : Time.utc(t.year, t.month + 1, 1)
        return false unless AvailKit.instant(data['period']['start']) == start && AvailKit.instant(data['period']['end']) == finish
        return false unless data['counters'].values.all? { |c| c['remaining'] == [0, c['limit'] - c['used']].max }
      end
      if %w[pruneExpiredReplays pruneHistory].include?(op)
        return false unless data['deleted'] <= body['limit'] && (!data['hasMore'] || data['deleted'] == body['limit'])
        return false if op == 'pruneHistory' && AvailKit.instant(data['asOf']) - AvailKit.instant(data['cutoff']) != 2_592_000
      end
      if op == 'events'
        previous = [query.fetch('after', '0').to_i, data['retentionFloor']].max
        return false if data['retentionFloor'] > data['highWater'] || data['events'].length > query.fetch('limit', '100').to_i
        data['events'].each do |event|
          return false unless event['sequence'] > previous
          previous = event['sequence']
        end
        return false unless data['nextAfter'] == previous && data['nextAfter'] <= [data['highWater'], query.fetch('after', '0').to_i].max
      end
      true
    rescue AvailKit::Error, ArgumentError, TypeError
      false
    end
  end
end
