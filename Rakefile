# frozen_string_literal: true

require "rake/testtask"
require "rubocop/rake_task"

Rake::TestTask.new(:test) do |t|
  t.libs << "lib" << "test"
  t.test_files = FileList["test/**/*_test.rb"]
end

RuboCop::RakeTask.new do |task|
  task.options = ["--config", "toolkit/rubocop/.rubocop.yml"]
end

task default: %i[rubocop test]

namespace :site do
  desc "Run example site integration tests"
  task :test do
    sh "bundle exec ruby -Ilib:test test/integration/example_site_test.rb"
  end

  desc "Build the demo site"
  task :build do
    Bundler.with_unbundled_env do
      Dir.chdir("demo/example.com") do
        sh "bundle install --quiet"
        sh "bundle exec jekyll build"
      end
    end
  end

  desc "Serve the demo site locally"
  task :serve do
    Bundler.with_unbundled_env do
      Dir.chdir("demo/example.com") do
        sh "bundle install --quiet"
        sh "bundle exec jekyll serve"
      end
    end
  end

  desc "Clean the demo site build"
  task :clean do
    Bundler.with_unbundled_env do
      Dir.chdir("demo/example.com") do
        sh "bundle exec jekyll clean"
      end
    end
  end
end
