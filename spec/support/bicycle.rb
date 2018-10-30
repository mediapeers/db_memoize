class Bicycle < ActiveRecord::Base
  include DbMemoize::Model

  def fuel_consumption
    0
  end
  db_memoize :fuel_consumption

  def gears_count
    5
  end
  db_memoize :gears_count

  def generic_value
    -1
  end
  db_memoize :generic_value

  def facilities
    {
      gears: 5,
      brakes: 2,
      light: false
    }
  end
  db_memoize :facilities

  def wise_saying
    nil
  end
  db_memoize :wise_saying
end

class ElectricBicycle < Bicycle
  def max_speed
    45
  end
  db_memoize :max_speed
end
