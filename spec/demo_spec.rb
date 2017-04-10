# frozen_string_literal: true

$DEBUG = true

require "faraday"
require "net/http"
require "rspec"
require "toxiproxy"
require "vcr"
require "webmock/rspec"

module ToxiproxyConfig
  PROXIES = JSON.parse(
    File.read("./spec/toxiproxy_config.json"),
    symbolize_names: true # toxiproxy-ruby expect symbols
  )

  def self.proxies
    PROXIES
  end

  def self.downstream(proxy_name)
    downstream = proxies.find do |proxy|
      proxy.fetch(:name) == proxy_name
    end

    downstream.fetch(:listen)
  end
end

VCR.configure do |conf|
  conf.cassette_library_dir = "./spec/vcr_cassettes"
  conf.hook_into :webmock

  conf.ignore_request do |request|
    request.uri.start_with?("http://127.0.0.1:8474/") # toxiproxy-server
  end
end

RSpec.configure do |conf|
  conf.before(:suite) do
    # start with a clean slate, destroy all proxies if any
    Toxiproxy.all.destroy
    Toxiproxy.populate(ToxiproxyConfig.proxies)
  end

  conf.after(:suite) do
    # be nice and end with a clean slate
    Toxiproxy.all.destroy
  end

  conf.disable_monkey_patching!
  conf.filter_run_when_matching :focus
  conf.warnings = true
  conf.order = :random
end

class HTTP
  def self.get(url, timeout:)
    http_client = Faraday.new do |faraday|
      faraday.adapter Faraday.default_adapter
    end

    http_client.get do |request|
      request.url(url)
      request.options.timeout = timeout
    end
  end
end

class NetHTTP
  def self.get(url, timeout:)
    uri = URI(url)
    http_client = Net::HTTP.new(uri.host, uri.port)
    http_client.read_timeout = timeout
    http_client.get(uri)
  end
end

RSpec.describe "HTTP" do
  describe "GET" do
    let(:example_timeout) { 1.0 }

    before do
      WebMock.allow_net_connect!
      VCR.turn_off!
    end

    after do
      VCR.turn_on!
      WebMock.disable_net_connect!
    end

    fcontext "when given a slow host" do
      let(:toxiproxy) { "http_host" }
      let(:url)       { "http://#{ToxiproxyConfig.downstream(toxiproxy)}/" }

      describe "open/read timeout" do
        around do |example|
          Toxiproxy[toxiproxy].toxic(:timeout, timeout: 0).apply do
            Timeout.timeout(example_timeout) do
              example.run
            end
          end
        end

        it "times out after a certain amount of time (Faraday)" do
          expect { HTTP.get(url, timeout: 0.1) }.to raise_error(Faraday::TimeoutError)
        end

        it "times out after a certain amount of time (Net::HTTP)" do
          expect { NetHTTP.get(url, timeout: 0.1) }.to raise_error(Net::ReadTimeout)
        end
      end
    end
  end
end
