require 'rubygems'
require 'spork'
require 'rake'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However, 
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

  # This file is copied to ~/spec when you run 'ruby script/generate rspec'
  # from the project root directory.
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path(File.join(File.dirname(__FILE__),'..','config','environment'))
  
  unless ActiveRecord::Migrator.new(:up, RAILS_ROOT + "/db/migrate").pending_migrations.empty?
    Rake::Task["db:test:prepare"].invoke
  end
  require 'spec/autorun'
  require 'spec/rails'

  # customizations ...

  # http://remarkable.rubyforge.org/
  # http://www.nomedojogo.com/2008/11/18/shoulda-for-rspec-is-remarkable/
  require 'remarkable_rails'
  # for testing authentication
  include AuthenticatedTestHelper
  include AuthenticatedSystem

  # end of customizations

  Spec::Runner.configure do |config|
    # If you're not using ActiveRecord you should remove these
    # lines, delete config/database.yml and disable :active_record
    # in your config/boot.rb
    config.use_transactional_fixtures = true
    config.use_instantiated_fixtures  = false
    config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

    # == Fixtures
    #
    # You can declare fixtures for each example_group like this:
    #   describe "...." do
    #     fixtures :table_a, :table_b
    #
    # Alternatively, if you prefer to declare them only once, you can
    # do so right here. Just uncomment the next line and replace the fixture
    # names with your fixtures.
    #
    # config.global_fixtures = :table_a, :table_b
    #
    # If you declare global fixtures, be aware that they will be declared
    # for all of your examples, even those that don't use them.
    #
    # You can also declare which fixtures to use (for example fixtures for test/fixtures):
    #
    # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
    #
    # == Mock Framework
    #
    # RSpec uses it's own mocking framework by default. If you prefer to
    # use mocha, flexmock or RR, uncomment the appropriate line:
    #
    # config.mock_with :mocha
    # config.mock_with :flexmock
    # config.mock_with :rr
    #
    # == Notes
    #
    # For more information take a look at Spec::Runner::Configuration and Spec::Runner
  end
  
  Dir.glob(File.dirname(__FILE__) + "/support/*.rb").each { |f| require(f) }
  
end

Spork.each_run do
  # This code will be run each time you run your specs.

end
