# frozen_string_literal: true

begin
  require "rspec/core/rake_task"

  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  warn "Could not require RSpec gem"
end

task default: [:spec]
