# Ruby 2.4 http timeout issue

[![Build Status](https://travis-ci.org/dentarg/ruby-2.4-http-timeout-issue.svg?branch=master)](https://travis-ci.org/dentarg/ruby-2.4-http-timeout-issue)

    brew install toxiproxy
    brew services start toxiproxy
<!-- -->

    bundle install

    bundle exec rake

Manual Toxiproxy

    brew services stop toxiproxy
    toxiproxy-server -config toxiproxy_config.json
    toxiproxy-cli toxic add http_host -t timeout -a timeout=0

