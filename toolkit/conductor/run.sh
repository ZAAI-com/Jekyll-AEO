#!/bin/bash
set -e

echo "==> Linting with RuboCop..."
bundle exec rubocop --config toolkit/rubocop/.rubocop.yml
echo "==> Linting passed."

echo ""
echo "==> Running tests..."
bundle exec rake test
echo "==> Tests passed."

echo ""
echo "==> Building demo site..."
bundle exec rake site:build
echo "==> Demo site built."

echo ""
echo "==> Building gem..."
gem build jekyll-aeo.gemspec
echo "==> Gem built."

echo ""
echo "==> All steps completed successfully."
