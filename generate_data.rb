# frozen_string_literal: true

require_relative './app'
require 'pry'

# ascent rate of 9m per min
include BaseCalculations

time = 15
deepest = 40.0
shallowest_stop = 5
ascent_rate_per_min = 9

current = deepest
current_average = deepest

while current.positive?
  current_average = ((current_average * time) + current) / (time + 1)
  time += 1
  obj =  Buhlmann.new(gas_mix_percentage: 0.21,
                      depth_in_meters: current_average,
                      exposure_time: time).call
  obj = obj.sort_by { |_k, val| val[:p_ambtol_meters] }.last
  p_comp = obj.last[:p_comp]
  tolerance = obj.last[:p_ambtol_meters]

  puts "#{time} current: #{current.round(2)}m, avg: #{current_average.round(2)}, p_comp: #{p_comp}, tol_m: #{tolerance.round(2)}"

  if tolerance < current_average && tolerance < current
    if tolerance > (current - ascent_rate_per_min)
      current = tolerance.round if current > shallowest_stop
    else
      current -= ascent_rate_per_min
    end
  end

  break if tolerance == 0
end
