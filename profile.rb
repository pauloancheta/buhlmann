# frozen_string_literal: true

require_relative './app'

class Profile
  include BaseCalculations

  ASCENT_RATE_PER_MIN = 10
  DESCENT_RATE_PER_MIN = 30

  attr_reader :time_at_depth, :deepest_depth_meters, :shallowest_stop_meters, :gas_mix_percentage,
    :current_depth, :current_time, :current_average_depth, :attitude

  def initialize(time_at_depth:, deepest_depth_meters:, shallowest_stop_meters:, gas_mix_percentage: 0.21)
    @time_at_depth = time_at_depth
    @deepest_depth_meters = deepest_depth_meters
    @shallowest_stop_meters = shallowest_stop_meters
    @gas_mix_percentage = gas_mix_percentage

    @current_depth = 0
    @current_time = 0
    @current_average_depth = 0.0
    @attitude = :descend
  end

  def run
    while attitude != :fin
      self.send(attitude)
      increment_time
      change_current_average_depth
      log
    end
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
    tol = compartment.gf_high_tol_meters.round

    return @attitude = :fin if tol < 1
    return if tol > current_depth - 3
    return @current_depth -= ASCENT_RATE_PER_MIN if tol < current_depth - ASCENT_RATE_PER_MIN

    @current_depth = tol
  end

  def compartment
    Buhlmann.new(gas_mix_percentage: gas_mix_percentage,
                 depth_in_meters: current_average_depth,
                 exposure_time: current_time).deepest_tolerance
  end

  def log
    puts({
      run: current_time,
      current_depth: current_depth,
      tol_m: compartment.p_ambtol_meters,
      gf_low_m: compartment.gf_low_tol_meters,
      gf_high_m: compartment.gf_high_tol_meters,
    })
  end
end

Profile.new(time_at_depth: 30,
            deepest_depth_meters: 40,
            shallowest_stop_meters: 3,
            gas_mix_percentage: 0.28).run
