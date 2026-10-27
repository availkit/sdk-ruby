# Every public wrapper is called through an actual HTTP fixture server.
def test_operation_matrix
  fixtures = JSON.parse(File.read(File.join(__dir__, "fixtures.json")))
  fixture = fixtures.fetch("createResource")
  with_server(status: 201, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.create_resource(fixture.fetch("request"))
    assert(result.is_a?(AvailKit::Model), "typed response createResource")
    request = requests.pop
    assert(request[:method] == "POST" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/resources", "route createResource")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
    assert(JSON.parse(request[:body]) == fixture["request"], "body createResource")
  end
  fixture = fixtures.fetch("listResources")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.list_resources()
    assert(result.is_a?(AvailKit::Model), "typed response listResources")
    request = requests.pop
    assert(request[:method] == "GET" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/resources", "route listResources")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
  end
  fixture = fixtures.fetch("setHours")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.replace_hours("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", fixture.fetch("request"))
    assert(result.is_a?(AvailKit::Model), "typed response setHours")
    request = requests.pop
    assert(request[:method] == "PUT" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/resources/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/hours", "route setHours")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
    assert(JSON.parse(request[:body]) == fixture["request"], "body setHours")
  end
  fixture = fixtures.fetch("getHours")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.get_hours("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    assert(result.is_a?(AvailKit::Model), "typed response getHours")
    request = requests.pop
    assert(request[:method] == "GET" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/resources/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/hours", "route getHours")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
  end
  fixture = fixtures.fetch("createOffering")
  with_server(status: 201, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.create_offering(fixture.fetch("request"))
    assert(result.is_a?(AvailKit::Model), "typed response createOffering")
    request = requests.pop
    assert(request[:method] == "POST" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/offerings", "route createOffering")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
    assert(JSON.parse(request[:body]) == fixture["request"], "body createOffering")
  end
  fixture = fixtures.fetch("listOfferings")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.list_offerings()
    assert(result.is_a?(AvailKit::Model), "typed response listOfferings")
    request = requests.pop
    assert(request[:method] == "GET" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/offerings", "route listOfferings")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
  end
  fixture = fixtures.fetch("availability")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.availability(offering_id: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", from: "2030-01-01T09:00:00Z", to: "2030-01-02T09:00:00Z")
    assert(result.is_a?(AvailKit::Model), "typed response availability")
    request = requests.pop
    assert(request[:method] == "GET" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/availability", "route availability")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
  end
  fixture = fixtures.fetch("book")
  with_server(status: 201, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.book(fixture.fetch("request"), idempotency_key: KEY)
    assert(result.is_a?(AvailKit::Model), "typed response book")
    request = requests.pop
    assert(request[:method] == "POST" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/bookings", "route book")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
    assert(JSON.parse(request[:body]) == fixture["request"], "body book")
  end
  fixture = fixtures.fetch("listBookings")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.list_bookings()
    assert(result.is_a?(AvailKit::Model), "typed response listBookings")
    request = requests.pop
    assert(request[:method] == "GET" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/bookings", "route listBookings")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
  end
  fixture = fixtures.fetch("cancel")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.cancel("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", idempotency_key: KEY)
    assert(result.is_a?(AvailKit::Model), "typed response cancel")
    request = requests.pop
    assert(request[:method] == "POST" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/bookings/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/cancel", "route cancel")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
    assert(JSON.parse(request[:body]) == fixture["request"], "body cancel")
  end
  fixture = fixtures.fetch("events")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.events()
    assert(result.is_a?(AvailKit::Model), "typed response events")
    request = requests.pop
    assert(request[:method] == "GET" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/events", "route events")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
  end
  fixture = fixtures.fetch("getResource")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.get_resource("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    assert(result.is_a?(AvailKit::Model), "typed response getResource")
    request = requests.pop
    assert(request[:method] == "GET" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/resources/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "route getResource")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
  end
  fixture = fixtures.fetch("updateResource")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.replace_resource("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", fixture.fetch("request"))
    assert(result.is_a?(AvailKit::Model), "typed response updateResource")
    request = requests.pop
    assert(request[:method] == "PUT" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/resources/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "route updateResource")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
    assert(JSON.parse(request[:body]) == fixture["request"], "body updateResource")
  end
  fixture = fixtures.fetch("getOffering")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.get_offering("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    assert(result.is_a?(AvailKit::Model), "typed response getOffering")
    request = requests.pop
    assert(request[:method] == "GET" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/offerings/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "route getOffering")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
  end
  fixture = fixtures.fetch("updateOffering")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.replace_offering("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", fixture.fetch("request"))
    assert(result.is_a?(AvailKit::Model), "typed response updateOffering")
    request = requests.pop
    assert(request[:method] == "PUT" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/offerings/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "route updateOffering")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
    assert(JSON.parse(request[:body]) == fixture["request"], "body updateOffering")
  end
  fixture = fixtures.fetch("getBooking")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.get_booking("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    assert(result.is_a?(AvailKit::Model), "typed response getBooking")
    request = requests.pop
    assert(request[:method] == "GET" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/bookings/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "route getBooking")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
  end
  fixture = fixtures.fetch("createWebhook")
  with_server(status: 201, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.create_webhook(fixture.fetch("request"))
    assert(result.is_a?(AvailKit::Model), "typed response createWebhook")
    request = requests.pop
    assert(request[:method] == "POST" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/webhooks", "route createWebhook")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
    assert(JSON.parse(request[:body]) == fixture["request"], "body createWebhook")
  end
  fixture = fixtures.fetch("listWebhooks")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.list_webhooks()
    assert(result.is_a?(AvailKit::Model), "typed response listWebhooks")
    request = requests.pop
    assert(request[:method] == "GET" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/webhooks", "route listWebhooks")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
  end
  fixture = fixtures.fetch("disableWebhook")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.disable_webhook("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    assert(result.is_a?(AvailKit::Model), "typed response disableWebhook")
    request = requests.pop
    assert(request[:method] == "POST" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/webhooks/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/disable", "route disableWebhook")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
    assert(JSON.parse(request[:body]) == fixture["request"], "body disableWebhook")
  end
  fixture = fixtures.fetch("listWebhookDeliveries")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.list_webhook_deliveries("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    assert(result.is_a?(AvailKit::Model), "typed response listWebhookDeliveries")
    request = requests.pop
    assert(request[:method] == "GET" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/webhooks/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/deliveries", "route listWebhookDeliveries")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
  end
  fixture = fixtures.fetch("getUsage")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.get_usage()
    assert(result.is_a?(AvailKit::Model), "typed response getUsage")
    request = requests.pop
    assert(request[:method] == "GET" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/usage", "route getUsage")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
  end
  fixture = fixtures.fetch("rescheduleBooking")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.reschedule_booking("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", fixture.fetch("request"), idempotency_key: KEY)
    assert(result.is_a?(AvailKit::Model), "typed response rescheduleBooking")
    request = requests.pop
    assert(request[:method] == "POST" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/bookings/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/reschedule", "route rescheduleBooking")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
    assert(JSON.parse(request[:body]) == fixture["request"], "body rescheduleBooking")
  end
  fixture = fixtures.fetch("archiveResource")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.archive_resource("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    assert(result.is_a?(AvailKit::Model), "typed response archiveResource")
    request = requests.pop
    assert(request[:method] == "POST" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/resources/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/archive", "route archiveResource")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
    assert(JSON.parse(request[:body]) == fixture["request"], "body archiveResource")
  end
  fixture = fixtures.fetch("archiveOffering")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.archive_offering("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    assert(result.is_a?(AvailKit::Model), "typed response archiveOffering")
    request = requests.pop
    assert(request[:method] == "POST" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/offerings/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/archive", "route archiveOffering")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
    assert(JSON.parse(request[:body]) == fixture["request"], "body archiveOffering")
  end
  fixture = fixtures.fetch("pruneHistory")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.prune_history(fixture.fetch("request"))
    assert(result.is_a?(AvailKit::Model), "typed response pruneHistory")
    request = requests.pop
    assert(request[:method] == "POST" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/maintenance/history", "route pruneHistory")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
    assert(JSON.parse(request[:body]) == fixture["request"], "body pruneHistory")
  end
  fixture = fixtures.fetch("createCustomer")
  with_server(status: 201, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.create_customer(fixture.fetch("request"))
    assert(result.is_a?(AvailKit::Model), "typed response createCustomer")
    request = requests.pop
    assert(request[:method] == "POST" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/customers", "route createCustomer")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
    assert(JSON.parse(request[:body]) == fixture["request"], "body createCustomer")
  end
  fixture = fixtures.fetch("listCustomers")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.list_customers()
    assert(result.is_a?(AvailKit::Model), "typed response listCustomers")
    request = requests.pop
    assert(request[:method] == "GET" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/customers", "route listCustomers")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
  end
  fixture = fixtures.fetch("getCustomer")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.get_customer("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    assert(result.is_a?(AvailKit::Model), "typed response getCustomer")
    request = requests.pop
    assert(request[:method] == "GET" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/customers/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "route getCustomer")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
  end
  fixture = fixtures.fetch("replaceCustomer")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.replace_customer("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", fixture.fetch("request"))
    assert(result.is_a?(AvailKit::Model), "typed response replaceCustomer")
    request = requests.pop
    assert(request[:method] == "PUT" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/customers/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "route replaceCustomer")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
    assert(JSON.parse(request[:body]) == fixture["request"], "body replaceCustomer")
  end
  fixture = fixtures.fetch("archiveCustomer")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.archive_customer("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    assert(result.is_a?(AvailKit::Model), "typed response archiveCustomer")
    request = requests.pop
    assert(request[:method] == "POST" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/customers/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/archive", "route archiveCustomer")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
    assert(JSON.parse(request[:body]) == fixture["request"], "body archiveCustomer")
  end
  fixture = fixtures.fetch("eraseCustomer")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.erase_customer("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    assert(result.is_a?(AvailKit::Model), "typed response eraseCustomer")
    request = requests.pop
    assert(request[:method] == "POST" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/customers/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/erase", "route eraseCustomer")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
    assert(JSON.parse(request[:body]) == fixture["request"], "body eraseCustomer")
  end
  fixture = fixtures.fetch("pruneExpiredReplays")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.prune_expired_replays(fixture.fetch("request"))
    assert(result.is_a?(AvailKit::Model), "typed response pruneExpiredReplays")
    request = requests.pop
    assert(request[:method] == "POST" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/maintenance/expired-replays", "route pruneExpiredReplays")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
    assert(JSON.parse(request[:body]) == fixture["request"], "body pruneExpiredReplays")
  end
  fixture = fixtures.fetch("getPublicPage")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::PublicClient.new(page_id: ID, base_url: origin)
    result = c.get_page()
    assert(result.is_a?(AvailKit::Model), "typed response getPublicPage")
    request = requests.pop
    assert(request[:method] == "GET" && request[:path].split("?").first == "/v1/public/pages/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "route getPublicPage")
    assert(request[:headers]["cookie"].nil?, "no cookie")
  end
  fixture = fixtures.fetch("listPublicOfferings")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::PublicClient.new(page_id: ID, base_url: origin)
    result = c.list_offerings()
    assert(result.is_a?(AvailKit::Model), "typed response listPublicOfferings")
    request = requests.pop
    assert(request[:method] == "GET" && request[:path].split("?").first == "/v1/public/pages/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/offerings", "route listPublicOfferings")
    assert(request[:headers]["cookie"].nil?, "no cookie")
  end
  fixture = fixtures.fetch("publicAvailability")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::PublicClient.new(page_id: ID, base_url: origin)
    result = c.availability(offering_id: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", from: "2030-01-01T09:00:00Z", to: "2030-01-02T09:00:00Z")
    assert(result.is_a?(AvailKit::Model), "typed response publicAvailability")
    request = requests.pop
    assert(request[:method] == "GET" && request[:path].split("?").first == "/v1/public/pages/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/availability", "route publicAvailability")
    assert(request[:headers]["cookie"].nil?, "no cookie")
  end
  fixture = fixtures.fetch("bookPublic")
  with_server(status: 201, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::PublicClient.new(page_id: ID, base_url: origin)
    result = c.book(fixture.fetch("request"), booking_token: TOKEN, contact_token: TOKEN, idempotency_key: KEY)
    assert(result.is_a?(AvailKit::Model), "typed response bookPublic")
    request = requests.pop
    assert(request[:method] == "POST" && request[:path].split("?").first == "/v1/public/pages/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/bookings", "route bookPublic")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["x-availkit-contact-token"] == TOKEN, "contact proof")
    assert(JSON.parse(request[:body]) == fixture["request"], "body bookPublic")
  end
  fixture = fixtures.fetch("getPublicBooking")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::PublicClient.new(page_id: ID, base_url: origin)
    result = c.get_booking("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", booking_token: TOKEN)
    assert(result.is_a?(AvailKit::Model), "typed response getPublicBooking")
    request = requests.pop
    assert(request[:method] == "GET" && request[:path].split("?").first == "/v1/public/pages/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/bookings/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "route getPublicBooking")
    assert(request[:headers]["cookie"].nil?, "no cookie")
  end
  fixture = fixtures.fetch("cancelPublicBooking")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::PublicClient.new(page_id: ID, base_url: origin)
    result = c.cancel("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", booking_token: TOKEN, idempotency_key: KEY)
    assert(result.is_a?(AvailKit::Model), "typed response cancelPublicBooking")
    request = requests.pop
    assert(request[:method] == "POST" && request[:path].split("?").first == "/v1/public/pages/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/bookings/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/cancel", "route cancelPublicBooking")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(JSON.parse(request[:body]) == fixture["request"], "body cancelPublicBooking")
  end
  fixture = fixtures.fetch("reschedulePublicBooking")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::PublicClient.new(page_id: ID, base_url: origin)
    result = c.reschedule("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", fixture.fetch("request"), booking_token: TOKEN, idempotency_key: KEY)
    assert(result.is_a?(AvailKit::Model), "typed response reschedulePublicBooking")
    request = requests.pop
    assert(request[:method] == "POST" && request[:path].split("?").first == "/v1/public/pages/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/bookings/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/reschedule", "route reschedulePublicBooking")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(JSON.parse(request[:body]) == fixture["request"], "body reschedulePublicBooking")
  end
  fixture = fixtures.fetch("getBookingPage")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.get_booking_page()
    assert(result.is_a?(AvailKit::Model), "typed response getBookingPage")
    request = requests.pop
    assert(request[:method] == "GET" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/booking-page", "route getBookingPage")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
  end
  fixture = fixtures.fetch("replaceBookingPage")
  with_server(status: 200, body: fixture.fetch("response")) do |origin, requests|
    c = AvailKit::Client.new(workspace_id: ID, environment: "test", credential: TOKEN, base_url: origin)
    result = c.replace_booking_page(fixture.fetch("request"))
    assert(result.is_a?(AvailKit::Model), "typed response replaceBookingPage")
    request = requests.pop
    assert(request[:method] == "PUT" && request[:path].split("?").first == "/v1/workspaces/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/booking-page", "route replaceBookingPage")
    assert(request[:headers]["cookie"].nil?, "no cookie")
    assert(request[:headers]["authorization"] == "Bearer " + TOKEN, "workspace authority")
    assert(JSON.parse(request[:body]) == fixture["request"], "body replaceBookingPage")
  end
end
