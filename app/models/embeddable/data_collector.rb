class Embeddable::DataCollector < ActiveRecord::Base
  DEFAULT_NAME = "Data Graph"
  MISSING_PROBE_MESSAGE = "Unable to find default probes. try running"
  set_table_name "embeddable_data_collectors"

  belongs_to :user
  belongs_to :probe_type, :class_name => 'Probe::ProbeType'
  belongs_to :calibration, :class_name => 'Probe::Calibration'
  belongs_to :prediction_graph_source,
    :class_name => "Embeddable::DataCollector",
    :foreign_key => "prediction_graph_id"

  has_many :prediction_graph_destinations,
    :class_name => "Embeddable::DataCollector",
    :foreign_key => "prediction_graph_id"
  has_many :page_elements, :as => :embeddable
  has_many :pages, :through =>:page_elements
  has_many :teacher_notes, :as => :authored_entity
  # diy_sensors is a simplified interface for a dataCollector.
  has_many :diy_sensors, :as => 'prototype'

  validates_presence_of :name, :message => "can't be blank"
  validate :associated_probe

  def associated_probe
    if self.probe_type
      unless Probe::ProbeType.find_by_id(self.probe_type_id)
        errors.add(:probe_type, "has bad id: #{self.probe_type_id}")
      end
    else
      errors.add(:probe_type, "is required")
      unless Probe::ProbeType.default
        self.errors.add(:probe_type, MISSING_PROBE_MESSAGE)
      end
    end
  end


  # proto-type datastores are hints for how to create diy-sensors
  named_scope :prototypes, :conditions => {:is_prototype => true}

  # this could work if the finder sql was redone
  # has_many :investigations,
  #   :finder_sql => 'SELECT embeddable_data_collectors.* FROM embeddable_data_collectors
  #   INNER JOIN page_elements ON embeddable_data_collectors.id = page_elements.embeddable_id AND page_elements.embeddable_type = "Embeddable::DataCollector"
  #   INNER JOIN pages ON page_elements.page_id = pages.id
  #   WHERE pages.section_id = #{id}'

  serialize :data_store_values

  acts_as_replicatable
  send_update_events_to :investigations

  def handle_probe_type_change
    self.calibration = nil
    fields = {
      :name         => proc { |p| "#{p.name} Data Collector"},
      :title        => proc { |p| "#{p.name} Data Collector"},
      :y_axis_label => proc { |p| p.name},
      :y_axis_units => proc { |p| p.unit},
      :y_axis_min   => proc { |p| p.min },
      :y_axis_max   => proc { |p| p.max }
    }
    # check to make sure the destination attribute values haven't 
    # also been changed concurrently ..
    fields.each_pair do |attr, lamb|
      unless self.send("#{attr.to_s}_changed?".to_sym)
        self.send("#{attr.to_s}=".to_sym, lamb.call(self.probe_type))
      end
    end
  end

  def before_validation
    if self.probe_type_id_changed?
      self.handle_probe_type_change
    end
  end

  def investigations
    invs = []
    self.pages.each do |page|
      inv = page.investigation
      invs << inv if inv
    end
  end

  include Changeable
  include Cloneable
  cloneable_associations :prediction_graph_destinations

  self.extend SearchableModel

  @@searchable_attributes = %w{uuid name description title x_axis_label x_axis_units y_axis_label y_axis_units}

  class <<self
    def searchable_attributes
      @@searchable_attributes
    end

    # find or make a prototype that matches this...
    def get_prototype(opts = {})
      return nil unless opts[:probe_type]
      conds = {}
      conds[:probe_type_id] = opts[:probe_type].id if opts[:probe_type]
      conds[:calibration_id] = opts[:calibration].id if opts[:calibration]
      conds[:graph_type_id] = self.graph_type_id_for(opts[:graph_type]) if opts[:graph_type]

      found = self.prototypes.find(:first, :conditions => conds)
      return found if found

      made = self.create
      made.probe_type = opts[:probe_type]
      made.name_from_probe_type
      made.is_prototype=true
      made.graph_type = opts[:graph_type]
      if opts[:calibration]
        made.calibration_id = opts[:calibration].id
      end
      made.save!
      return made
    end
  end

  def other_data_collectors_in_activity_scope(scope)
    if scope && scope.class != Embeddable::DataCollector
      scope.activity.data_collectors - [self]
    else
      []
    end
  end

  def self.by_scope(scope)
    if scope && scope.class != Embeddable::DataCollector
      scope.activity.investigation.data_collectors
    else
      []
    end
  end

  def self.prediction_graphs
    Embeddable::DataCollector.find_all_by_graph_type_id(2)
  end

  def ot_button_str
    buttons = '0,1,2,3,4'
    buttons << ',5' if ruler_enabled
    buttons << ',6' if autoscale_enabled
    buttons
  end

  def valid_calibrations
    if probe_type
      probe_type.calibrations
    else
      []
    end
  end

  # move to helper
  def calibration_select
    self.valid_calibrations.collect {|c| [c.name,c.id] }
  end

  # def calibration
  #   return nil
  # end
  #
  # def calibration=(calibration)
  #   if probe_type.calibrations.include?(calibration)
  #     puts "hazzza"
  #   else
  #     puts "boo"
  #   end
  # end

  def self.graph_types
    [["Sensor", 1], ["Prediction", 2]]
  end

  def self.graph_type_id_for(gtype)
    self.graph_types.select{|gt| gt[0] == gtype}.first[1]
  end

  def graph_type_id
    self[:graph_type_id] || 1
  end

  def graph_type_id=(gid)
    self[:graph_type_id] = gid
  end

  def graph_type
    Embeddable::DataCollector.graph_types[graph_type_id-1][0]
  end

  def graph_type=(gtype)
    self[:graph_type_id] = Embeddable::DataCollector.graph_type_id_for(gtype)
  end

  def y_axis_title
    "#{self.y_axis_label} (#{self.y_axis_units})"
  end

  def x_axis_title
    "#{self.x_axis_label} (#{self.x_axis_units})"
  end

  default_value_for :description, "Data Collector Graphs can be used for sensor data or predictions."
  default_value_for :name, Embeddable::DataCollector::DEFAULT_NAME
  # default_value_for :y_axis_label, default_probe_type.name
  # default_value_for :y_axis_label, 'Temperature'

  default_values :x_axis_min                  =>  0,
                 :x_axis_max                  =>  30,
                 :x_axis_label                =>  "Time",
                 :x_axis_units                =>  "s",
                 :multiple_graphable_enabled  =>  false,
                 :draw_marks                  =>  false,
                 :connect_points              =>  true,
                 :autoscale_enabled           =>  false,
                 :ruler_enabled               =>  false,
                 :show_tare                   =>  false,
                 :single_value                =>  false

  default_value_for :probe_type do |v|
    Probe::ProbeType.default
  end

  def name_from_probe_type
    self.name = "#{self.probe_type.name} Data Collector"
  end

  # send_update_events_to :investigations

  def display_type
    graph_type
  end

  def self.display_name
    "Graph"
  end

  def self.authorable_in_java?
    true
  end

  def authorable_in_java?
    Embeddable::DataCollector.authorable_in_java?
  end

  def update_from_otml_library_content
    olc = Hash.from_xml(otml_library_content)
    if ot_data_collector = olc['OTDataCollector']
      self.name = ot_data_collector['name']
      self.title = ot_data_collector['title']
      self.autoscale_enabled = ot_data_collector['autoScaleEnabled'] == 'true'
      if ot_data_axis = ot_data_collector['xDataAxis']['OTDataAxis']
        self.x_axis_label = ot_data_axis['label']
        self.x_axis_units = ot_data_axis['units']
        self.x_axis_min   = ot_data_axis['min'].to_f
        self.x_axis_max   = ot_data_axis['max'].to_f
      end
      if ot_data_axis = ot_data_collector['yDataAxis']['OTDataAxis']
        self.y_axis_label = ot_data_axis['label']
        self.y_axis_units = ot_data_axis['units']
        self.y_axis_min   = ot_data_axis['min'].to_f
        self.y_axis_max   = ot_data_axis['max'].to_f
      end
      if ot_data_graphable = ot_data_collector['source']['OTDataGraphable']
         self.connect_points = ot_data_graphable['connectPoints']
         self.draw_marks = ot_data_graphable['drawParks'] == 'true'
         if ot_data_store = ot_data_graphable['dataStore']['OTDataStore']
           if values = ot_data_store['values']
             if delta_time = ot_data_store['dt']
               delta_time = delta_time.to_f
               time = 0.0
               self.data_store_values = []
               values['float'].each do |v|
                 self.data_store_values << time
                 self.data_store_values << v.to_f
                 time += delta_time
               end
             else
               self.data_store_values = values['float'].collect { |v| v.to_f }
             end
           else
             self.data_store_values = []
           end
         end
      end
      self.save
    end
  end

end

