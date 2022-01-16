# frozen_string_literal: true

require './app'

# 40/85
# depth 40 time 30
# 40 bot 30
# 15 asc 33
# 15 2 35
# 12 4 39
# 9 5 44
# 6 48 92
#
class Profile
  include BaseCalculations

  ASCENT_RATE_PER_MIN = 10
  DESCENT_RATE_PER_MIN = 15

  attr_reader :time_at_depth, :deepest_depth_meters, :shallowest_stop_meters, :gas_mix_percentage,
    :current_depth, :current_time, :current_average_depth, :attitude,
    :gf_low_percentage, :gf_high_percentage

  def initialize(time_at_depth:,
                 deepest_depth_meters:,
                 shallowest_stop_meters:,
                 gas_mix_percentage: 0.21,
                 gf_low_percentage: 1, gf_high_percentage: 1)
    @time_at_depth = time_at_depth
    @deepest_depth_meters = deepest_depth_meters
    @shallowest_stop_meters = shallowest_stop_meters
    @gas_mix_percentage = gas_mix_percentage
    @gf_low_percentage = gf_low_percentage
    @gf_high_percentage = gf_high_percentage

    @current_depth = 0
    @current_time = 0
    @current_average_depth = 0.0
    @attitude = :descend
    @collection = Hash.new({})
  end

  def run
    while attitude != :fin
      log
      self.send(attitude)
      increment_time
      change_current_average_depth
    end

    @collection
  end

  private

  def increment_time
    @current_time += 1
  end

  def change_current_average_depth
    gross_depth_at_time = (current_average_depth * current_time) + current_depth
    avg_depth_at_time = gross_depth_at_time / (current_time + 1)

    @current_average_depth = avg_depth_at_time.round(2)
  end

  def descend
    if (current_depth + DESCENT_RATE_PER_MIN) < deepest_depth_meters
      @current_depth += DESCENT_RATE_PER_MIN
    else
      @attitude = :stay
      @current_depth = deepest_depth_meters
    end
  end

  def stay
    @attitude = :ascend unless current_time < time_at_depth - 1
  end

  def ascend
    tol = compartment.p_ambtol_meters.round
    next_depth = (current_depth - (current_depth % 3))
    maybe_ascent_depth = current_depth - ASCENT_RATE_PER_MIN

    return @attitude = :fin if compartment.p_ambtol_meters < 0.05
    return if tol > current_depth

    @current_depth = [[tol, maybe_ascent_depth].max, next_depth].min
  end

  def compartments
    Buhlmann.new(gas_mix_percentage: gas_mix_percentage,
                 depth_in_meters: current_average_depth,
                 exposure_time: current_time,
                 gf_low_percentage: gf_low_percentage,
                 gf_high_percentage: gf_high_percentage)
  end

  def compartment
    pp compartments.compartments.select { |c| c.id == 1 }.first.p_ambtol
    compartments.deepest_tolerance
  end

  def log
    @collection[current_time] = compartments
    # puts({
    #   run: current_time,
    #   current_depth: current_depth,
    #   tol_m: compartment.p_ambtol_meters,
    #   gf_low_m: compartment.gf_low_tol_meters,
    #   gf_high_m: compartment.gf_high_tol_meters,
    # })
  end
end
