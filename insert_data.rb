require 'benchmark'
require 'bundler'
require 'optparse'

Bundler.require

def build_title
  (0...8).map{ ('A'.ord + rand(26)).chr }.join
end

def build_url
  'http://' + (0...8).map{ ('a'.ord + rand(26)).chr }.join + '.com'
end

# parse option
option_hash = {}
OptionParser.new { |opt|
  options = {}
  opt.on('-c') { |v| option_hash[:c] = v }
  opt.on('-t TABLE') { |v| option_hash[:t] = v }
  opt.on('-n NUM') { |v| option_hash[:n] = v.to_i }
  opt.on('--non-bulk') { |v| option_hash[:non_bulk] = v }
  opt.parse!(ARGV)
}  

puts option_hash

# connect mysql
client = Mysql2::Client.new(username: 'root', database: 'workshop')

# truncate table
if option_hash[:c]
  client.query("TRUNCATE TABLE #{option_hash[:t]}")
end

# insert data
BULK_SIZE = 1_000
result = Benchmark.realtime do
  values = []
  option_hash[:n].times do |i|
    values.push "(null, #{rand(10_000) + 1}, '#{build_title}', '#{build_url}', 'description #{i}')"

    if option_hash[:non_bulk] || values.count == BULK_SIZE
      client.query("INSERT INTO #{option_hash[:t]} VALUES " << values.join(','))
      values.clear
    end
  end
end

puts "#{result}s"
