require_relative 'task-1.rb'
require 'rspec-benchmark'

RSpec.configure do |config|
  config.include RSpec::Benchmark::Matchers
end

def worker
  work(filename = 'data_1X.txt', disable_gc: false)
end

describe 'Performance' do
  describe 'linear work' do
    let(:time) { 80 }
    it 'works under 100 ms' do
      expect {
        worker
      }.to perform_under(time).ms.warmup(2).times.sample(10).times
    end

    let(:measurement_time_seconds) { 1 }
    let(:warmup_seconds) { 0.2 }
    let(:ips) { 12 }
    it 'works faster than 10 ips' do
      expect {
        worker
      }.to perform_at_least(ips).within(measurement_time_seconds).warmup(warmup_seconds).ips
    end
  end
end
