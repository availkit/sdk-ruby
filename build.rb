# frozen_string_literal: true
# Usage: ruby build.rb OUTPUT_DIRECTORY
require 'fileutils'
require 'rubygems/package'
abort 'Usage: ruby build.rb OUTPUT_DIRECTORY' unless ARGV.length == 1
out = File.expand_path(ARGV[0]); FileUtils.mkdir_p(out)
Dir.chdir(__dir__) do
  spec = Gem::Specification.load('availkit.gemspec')
  Gem::Package.build(spec, false, false, File.join(out, "availkit-#{spec.version}.gem"))
end
