class Bicycle < ActiveRecord::Base
  include DbMemoize::Model

  def gears_count
    5
  end
  db_memoize :gears_count

  def shift(gears)
    "#{gears} shifted!"
  end
  db_memoize :shift

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
