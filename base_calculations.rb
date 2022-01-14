# frozen_string_literal: true

module BaseCalculations
  def pressure_to_meters(pressure)
    return 0 if pressure < 1

    (pressure - 1) * 30
  end

  def meters_to_pressure(meters)
    (meters / 10) + 1
  end

  def partial_pressure_n(meters, nitrogen = 0.79)
    atm = (meters / 10) + 1
    nitrogen * atm
  end
end
