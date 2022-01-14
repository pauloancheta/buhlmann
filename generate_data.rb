# frozen_string_literal: true

require_relative './app'
require 'pry'

# ascent rate of 9m per min
include BaseCalculations

ascent_rate_per_min = 9
descent_rate_per_min = 15

current_time = 0
time_at_depth = 16
deepest = 40.0
shallowest_stop = 5

current = 0
current_average = 0

while current < deepest
  obj =  Buhlmann.new(gas_mix_percentage: 0.21,
                      depth_in_meters: current_average,
                      exposure_time: current_time).deepest_tolerance
  tolerance = obj.p_ambtol_meters

  if !((current + descent_rate_per_min) > deepest)
    current += descent_rate_per_min
  else
    current = deepest
  end

  puts "#{current_time} current: #{current}m, avg: #{current_average}, p_comp: #{obj.p_comp.round(2)}, tol_m: #{tolerance.round(2)}"

  current_average = (((current_average * current_time) + current) / (current_time + 1)).round(2)
  current_time += 1
end

while current_time < time_at_depth
  obj =  Buhlmann.new(gas_mix_percentage: 0.21,
                      depth_in_meters: current_average,
                      exposure_time: current_time).deepest_tolerance
  tolerance = obj.p_ambtol_meters

  puts "#{current_time} current: #{current}m, avg: #{current_average}, p_comp: #{obj.p_comp.round(2)}, tol_m: #{tolerance.round(2)}"

  current_average = (((current_average * current_time) + current) / (current_time + 1)).round(2)
  current_time += 1
end

while current.positive?
  obj =  Buhlmann.new(gas_mix_percentage: 0.21,
                      depth_in_meters: current_average,
                      exposure_time: current_time).deepest_tolerance

  current_average = (((current_average * current_time) + current) / (current_time + 1)).round(2)
  current_time += 1
  tolerance = obj.p_ambtol_meters

  puts "#{current_time} current: #{current}m, avg: #{current_average}, p_comp: #{obj.p_comp.round(2)}, tol_m: #{tolerance.round(2)}"

  if tolerance < current_average && tolerance < current
    if tolerance > (current - ascent_rate_per_min)
      current = tolerance.round if current > shallowest_stop
    else
      current -= ascent_rate_per_min
    end
  end

  break if tolerance == 0
end
