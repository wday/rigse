class Saveable::Sparks::MeasuringResistanceReport < ActiveRecord::Base
  set_table_name "saveable_sparks_measuring_resistance_reports"

  belongs_to :measuring_resistance,  :class_name => 'Saveable::Sparks::MeasuringResistance'

  acts_as_list :scope => :measuring_resistance_id
  
end
