# frozen_string_literal: true
require 'pry'
require_relative './base_calculations'

# Basic Buhlmann decompression algorithm from:
# https://web.archive.org/web/20100215060446/http://njscuba.net/gear/trng_10_deco.html
# Please don't use this as source of your decompression stops. This is purely for resesarch only.
# As you can see, there are no tests written.
#
# DO NOT USE THIS AS A DIVE PLANNER!

NITROGEN_COMPARTMENTS = {
  1  => { half_time: 4.0,   a: 1.2599, b: 0.5050 },
  2  => { half_time: 8.0,   a: 1.0000, b: 0.6514 },
  3  => { half_time: 12.5,  a: 0.8618, b: 0.7222 },
  4  => { half_time: 18.5,  a: 0.7562, b: 0.7725 },
  5  => { half_time: 27.0,  a: 0.6667, b: 0.8125 },
  6  => { half_time: 38.3,  a: 0.5933, b: 0.8434 },
  7  => { half_time: 54.3,  a: 0.5282, b: 0.8693 },
  8  => { half_time: 77.0,  a: 0.4701, b: 0.8910 },
  9  => { half_time: 109.0, a: 0.4187, b: 0.9092 },
  10 => { half_time: 146.0, a: 0.3798, b: 0.9222 },
  11 => { half_time: 187.0, a: 0.3497, b: 0.9319 },
  12 => { half_time: 239.0, a: 0.3223, b: 0.9403 },
  13 => { half_time: 305.0, a: 0.2971, b: 0.9477 },
  14 => { half_time: 390.0, a: 0.2737, b: 0.9544 },
  15 => { half_time: 498.0, a: 0.2523, b: 0.9602 },
  16 => { half_time: 635.0, a: 0.2327, b: 0.9653 }
}

HELIUM_COMPARTMENTS = {
  1  => { half_time: 1.5,   a: 1.7435, b: 0.1911 },
  2  => { half_time: 3.0,   a: 1.3838, b: 0.4295 },
  3  => { half_time: 4.7,   a: 1.1925, b: 0.5446 },
  4  => { half_time: 7.0,   a: 1.0465, b: 0.6265 },
  5  => { half_time: 10.2,  a: 0.9226, b: 0.6917 },
  6  => { half_time: 14.5,  a: 0.8211, b: 0.7420 },
  7  => { half_time: 20.5,  a: 0.7309, b: 0.7841 },
  8  => { half_time: 29.1,  a: 0.6506, b: 0.8195 },
  9  => { half_time: 41.1,  a: 0.5794, b: 0.8491 },
  10 => { half_time: 55.1,  a: 0.5256, b: 0.8703 },
  11 => { half_time: 70.6,  a: 0.4840, b: 0.8860 },
  12 => { half_time: 90.2,  a: 0.4460, b: 0.8997 },
  13 => { half_time: 115.1, a: 0.4112, b: 0.9118 },
  14 => { half_time: 147.2, a: 0.3788, b: 0.9226 },
  15 => { half_time: 187.9, a: 0.3492, b: 0.9321 },
  16 => { half_time: 239.6, a: 0.3220, b: 0.9404 }
}

# Pcomp = Pbegin + [ Pgas - Pbegin ] x [ 1 - 2 ^ ( - te / tht ) ]
# where:
#
# Pcomp = Inert gas pressure in the mixture being breathed ( ATM )
# Pbegin = Inert gas pressure in the compartment after the exposure time ( ATM )
# Pgas = Length of the exposure time ( minutes )
# te = Half time of the compartment ( minutes )
# tht	= Inert gas pressure in the compartment before the exposure time ( ATM )
#
# Pambtol = ( Pcomp - a ) x b
# Pcomp = inert gas in the compartment ( ATM )
# Pambtol = is the pressure you could drop to ( ATM )
#
# 1 ATM = 14.7 psia ( 1 Atmosphere, or sea level standard pressure )
class Buhlmann
  include BaseCalculations
  attr_reader :gas_mix_percentage, :depth_in_meters, :exposure_time, :compartments

  def initialize(gas_mix_percentage: 0.21,
                 depth_in_meters:,
                 exposure_time: 10,
                 gf_low_percentage: 0.40,
                 gf_high_percentage: 0.85)
    @gas_mix_percentage = gas_mix_percentage
    @depth_in_meters = depth_in_meters.to_f
    @exposure_time = exposure_time

    @compartments = (1..16).map do |compartment|
      ambtol = p_ambtol(compartment)
      Compartment.new(compartment, p_comp(compartment), ambtol,
                      gf_low_percentage, gf_high_percentage)
    end
  end

  def deepest_tolerance
    compartments.sort { |val| val.p_ambtol_meters }.last
  end

  private

  # Pambtol = is the pressure you could drop to ( ATM )
  def p_ambtol(compartment)
    (p_comp(compartment) - a_modifier(compartment)) * b_modifier(compartment)
  end

  # Pcomp = Inert gas pressure in the mixture being breathed ( ATM )
  def p_comp(compartment)
    p_begin + (p_gas - p_begin) * (1 - 2**(-exposure_time / half_time(compartment)))
  end

  def p_gas
    meters_to_pressure(depth_in_meters) * p_begin
  end

  def half_time(compartment)
    NITROGEN_COMPARTMENTS.fetch(compartment).fetch(:half_time)
  end

  def p_begin
    1 - gas_mix_percentage
  end

  # these value can also be taken from the nitrogen compartments a constant
  # a = 2 x ( tht ^ -1/3 )
  def a_modifier(compartment)
    2 * (half_time(compartment)**(-1 / 3.0))
  end

  # these value can also be taken from the nitrogen compartments b constant
  # b = 1.005 - ( tht ^ - 1/2 )
  def b_modifier(compartment)
    (1.005 - (half_time(compartment)**(-1 / 2.0)))
  end

  class Compartment
    include BaseCalculations
    attr_reader :id, :p_comp, :p_ambtol, :gf_low, :gf_high

    def initialize(id, p_comp, p_ambtol, gf_low, gf_high)
      @id = id
      @p_comp = p_comp
      @p_ambtol = p_ambtol
      @gf_low = 1 - gf_low + 1
      @gf_high = 1 - gf_high + 1
    end

    def p_ambtol_meters
      ans = pressure_to_meters(p_ambtol)
      ans < 0 ? 0 : ans
    end

    def gf_low_tol
      p_ambtol * gf_low
    end

    def gf_high_tol
      p_ambtol * gf_high
    end

    def gf_low_tol_meters
      return 0 if p_ambtol_meters < 0
      p_ambtol_meters * gf_low
    end

    def gf_high_tol_meters
      return 0 if p_ambtol_meters < 0

      p_ambtol_meters * gf_high
    end
  end
end
