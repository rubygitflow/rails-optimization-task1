require_relative 'task-1.rb'
require 'rspec-benchmark'

RSpec.configure do |config|
  config.include RSpec::Benchmark::Matchers
end

def worker
  work(filename = 'data_1X.txt', disable_gc: false)
end

def create_file(size)
  system("head -n #{size} data_large.txt > data_#{size}.txt")
end

def linear_work(size)
  create_file(size)
  work(filename = "data_#{size}.txt", disable_gc: false)
end

describe 'Performance' do
  describe 'linear work' do
    let(:time) { 40 }
    it 'works under 40 ms' do
      expect {
        worker
      }.to perform_under(time).ms.warmup(2).times.sample(10).times
    end

    let(:measurement_time_seconds) { 1 }
    let(:warmup_seconds) { 0.2 }
    let(:ips) { 25 }
    it 'works faster than 25 ips' do
      expect {
        worker
      }.to perform_at_least(ips).within(measurement_time_seconds).warmup(warmup_seconds).ips
    end

    let(:sizes) { [16000, 32000, 64000] }
    it 'performs linear' do
        expect { |n, _i| linear_work(n) }.to perform_linear.in_range(sizes)
    end
  end
end
