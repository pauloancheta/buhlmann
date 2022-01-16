# frozen_string_literal: true

require_relative './profile'
require 'pry'

COLORS = %w|
  #4FFA93
  #86C1CA
  #113315
  #327152
  #B4EEE6
  #5C51C0
  #B96943
  #F9BFCD
  #09A8FF
  #46FC07
  #750E36
  #94C66A
  #636459
  #182423
  #D07D07
|

collection = Profile.new(
  time_at_depth: 30,
  deepest_depth_meters: 40,
  shallowest_stop_meters: 3,
  gas_mix_percentage: 0.28,
  gf_low_percentage: 1,
  gf_high_percentage: 1
).run

full_string_array = []
full_string_array << "const labels = [#{collection.keys.join(",")}]"

hash = Hash.new()
collection.each do |key, compartments|
  compartments.compartments.each do |compartment|
    if hash[compartment.id].nil?
      hash[compartment.id] = [compartment.p_ambtol_meters]
    else
      hash[compartment.id] << compartment.p_ambtol_meters
    end
  end
end

full_string_array << "const datasets = ["
hash.each do |key, value|
  full_string_array << """  { label: '#{key}', backgroundColor: '#{COLORS[key]}', borderColor: '#{COLORS[key]}', data: [#{value.join(",")}] },"""
end

full_string_array << "]"

full_string_array << """
const data = {
  labels: labels,
  datasets: datasets
};

const myChart = new Chart(
  document.getElementById('myChart'),
  { type: 'line', data: data, options: {} }
);
"""

path_to_file = './assets/javascript/populate_chart.js'
File.delete(path_to_file) if File.exist?(path_to_file)
File.write(path_to_file, full_string_array.join("\n"))
