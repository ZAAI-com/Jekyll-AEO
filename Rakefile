# frozen_string_literal: true

require "rake/testtask"
require "rubocop/rake_task"

Rake::TestTask.new(:test) do |t|
  t.libs << "lib" << "test"
  t.test_files = FileList["test/**/*_test.rb"]
end

RuboCop::RakeTask.new

task default: %i[rubocop test]

namespace :site do
  desc "Run example site integration tests"
  task :test do
    sh "bundle exec ruby -Ilib:test test/integration/example_site_test.rb"
  end

  desc "Build the test site"
  task :build do
    Dir.chdir("test/example.com") do
      sh "bundle install --quiet"
      sh "bundle exec jekyll build"
    end
  end

  desc "Serve the test site locally"
  task :serve do
    Dir.chdir("test/example.com") do
      sh "bundle install --quiet"
      sh "bundle exec jekyll serve"
    end
  end

  desc "Clean the test site build"
  task :clean do
    Dir.chdir("test/example.com") do
      sh "bundle exec jekyll clean"
    end
  end
end
