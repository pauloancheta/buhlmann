# frozen_string_literal: true

require_relative './app'
require 'pry'

# ascent rate of 9m per min
include BaseCalculations

ascent_rate_per_min = 10
descent_rate_per_min = 30

current_time = 0
time_at_depth = 30
deepest = 40.0
shallowest_stop = 3
mix_percent = 0.28

# stp time run
# 40 bot 30
# 12 asc 33
# 12 2 35
# 9 3 38
# 6 6 44
# 3 15 59

current = 0
current_average = 0

# puts "begin descent"
while current < deepest
  current_time += 1
  current_average = (((current_average * current_time) + current) / (current_time + 1)).round(2)
  obj =  Buhlmann.new(gas_mix_percentage: mix_percent,
                      depth_in_meters: current_average,
                      exposure_time: current_time).deepest_tolerance
  tolerance = obj.p_ambtol_meters

  if !((current + descent_rate_per_min) > deepest)
    current += descent_rate_per_min
  else
    current = deepest
  end

  puts "run: #{current_time} current_depth: #{current}m, tol_m: #{tolerance.round(2)} low/high: #{obj.gf_low_tolerance_meters}/#{obj.gf_high_tolerance_meters}"
  # print "#{ current }, "

end

# puts "stay at depth"
while current_time < time_at_depth
  obj =  Buhlmann.new(gas_mix_percentage: mix_percent,
                      depth_in_meters: current_average,
                      exposure_time: current_time).deepest_tolerance
  tolerance = obj.p_ambtol_meters

  puts "run: #{current_time} current_depth: #{current}m, tol_m: #{tolerance.round(2)} low/high: #{obj.gf_low_tolerance_meters}/#{obj.gf_high_tolerance_meters}"
  # print "#{ current }, "

  current_time += 1
  current_average = (((current_average * current_time) + current) / (current_time + 1)).round(2)
end

# puts "begin ascent"
while current.positive?
  obj =  Buhlmann.new(gas_mix_percentage: mix_percent,
                      depth_in_meters: current_average,
                      exposure_time: current_time).deepest_tolerance
  tolerance = obj.p_ambtol_meters

  if tolerance < (current - 3)
    if tolerance > (current - ascent_rate_per_min)
      current = tolerance.round if tolerance.round >= shallowest_stop
    else
      current -= ascent_rate_per_min
    end
  end

  puts "run: #{current_time} current_depth: #{current}m, tol_m: #{tolerance.round(2)} low/high: #{obj.gf_low_tolerance_meters}/#{obj.gf_high_tolerance_meters}"
  # print "#{ current }, "

  break if tolerance < 1
  current_time += 1
  current_average = (((current_average * current_time) + current) / (current_time + 1)).round(2)
end
