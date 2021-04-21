require_relative 'task-1.rb'
require 'benchmark'

time = Benchmark.realtime do
  work(filename = 'data_1X.txt', disable_gc: true)
end

puts "Finish in #{time.round(2)}"
