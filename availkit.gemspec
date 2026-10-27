# frozen_string_literal: true
Gem::Specification.new do |s|
  s.name = 'availkit'
  s.version = '0.1.1'
  s.summary = 'Explicit-scope, send-once AvailKit workspace and public booking SDK'
  s.description = 'Typed immutable models, retained original booking intents, bounded TLS transport and webhook verification.'
  s.authors = ['AvailKit']
  s.homepage = 'https://availkit.dev/sdk/ruby'
  s.license = 'MIT'
  s.required_ruby_version = '>= 3.3', '< 4.1'
  # This exact source list cannot admit local credentials, intents, caches,
  # dependency trees or new files merely because they share a source extension.
  s.files = %w[
    README.md LICENSE coverage.json runtime-policy.json availkit.gemspec build.rb
    lib/availkit.rb lib/availkit/models.rb lib/availkit/operations.rb
    lib/availkit/relations.rb lib/availkit/operations.json lib/availkit/schemas.json
    examples/first-booking.rb examples/public-booking.rb examples/webhook.rb
    test/sdk_test.rb test/matrix.rb test/fixtures.json test/package_test.py
    VERSION CHANGELOG.md SECURITY.md SUPPORT.md DEVELOPMENT.md contract-projection.json contracts/api.openapi.json contracts/check_projection.py
  ].sort
  root = File.expand_path(__dir__)
  s.files.each do |relative|
    current = root
    relative.split('/').each do |part|
      current = File.join(current, part)
      raise 'symlink package input rejected' if File.symlink?(current)
    end
    raise 'nonregular or missing package input rejected' unless File.file?(current)
  end
  s.require_paths = ['lib']
  s.metadata = {'documentation_uri' => 'https://availkit.dev/sdk/ruby', 'homepage_uri' => 'https://availkit.dev', 'source_code_uri' => 'https://github.com/availkit/sdk-ruby', 'bug_tracker_uri' => 'https://github.com/availkit/sdk-ruby/issues', 'changelog_uri' => 'https://github.com/availkit/sdk-ruby/blob/main/CHANGELOG.md', 'rubygems_mfa_required' => 'true'}
end
