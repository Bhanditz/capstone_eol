ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

require 'spec/autorun'
require 'spec/rails'
require 'capybara/rails'
require 'capybara/dsl'


load 'composite_primary_keys/fixtures.rb'
require 'csv'

# just enough infrastructure to get 'assert_select' to work
require 'action_controller'
require 'action_controller/assertions/selector_assertions'
include ActionController::Assertions::SelectorAssertions


require "email_spec/helpers"
require "email_spec/matchers"

# Capybara.default_driver = :selenium

# commented out as these were getting loaded too many times
# require File.expand_path(File.dirname(__FILE__) + "/factories")
require File.expand_path(File.dirname(__FILE__) + "/eol_spec_helpers")
require File.expand_path(File.dirname(__FILE__) + "/custom_matchers")

require 'eol_scenarios'
EolScenario.load_paths = [ File.join(RAILS_ROOT, 'scenarios') ]

Spec::Runner.configure do |config|
  include EolScenario::Spec
  include EOL::Data # this gives us access to methods that clean up our data (ie: lft/rgt values)
  include EOL::DB   # this gives us access to methods that handle transactions
  include EOL::Spec::Helpers

  config.use_transactional_fixtures = false

  config.include EOL::Spec::Matchers
  config.include(EmailSpec::Helpers)
  config.include(EmailSpec::Matchers)
  config.include(Capybara, :type => :integration)

  # before running any spec, especially when running them individually, we'll want to truncate the database
  truncate_all_tables

  config.after(:each) do
    $CACHE.clear if $CACHE
    # reset the class variables that cache certain instances
    reset_all_model_cached_instances
  end

end

def reset_all_model_cached_instances
  $ALL_MODELS ||= Dir.foreach("#{RAILS_ROOT}/app/models").map do |model_path|
    if m = model_path.match(/^(([a-z]+_)*[a-z]+)\.rb$/)
      m[1].camelcase.constantize
    else
      nil
    end
  end.compact
  $ALL_MODELS.each do |model|
    model.reset_cached_instances rescue nil
  end
end

# quiet down any migrations that run during tests
ActiveRecord::Migration.verbose = false

def wait_for_insert_delayed(&block)
  countdown = 10
  begin
    yield
    return
  rescue Spec::Expectations::ExpectationNotMetError => e
    countdown -= 1
    sleep(0.2)
    retry if countdown > 0
    raise e
  end
end

def read_test_file(filename)
  csv_obj = CSV.open(File.expand_path(RAILS_ROOT + "/spec/csv_files/" + filename), "r", "\t")
  field_names = []
  field_name = ''
  csv_obj.each_with_index do |fields, i|
    if i == 0
      field_names = fields
    else
      result = {}
      field_names.each_with_index do |field_name, ii|
        result[field_name] = fields[ii]
      end
      yield(result)
    end
  end
end

module Spec
  module Rails
    module Example
      class FunctionalExampleGroup < ActionController::TestCase
        # All we need to do is keep a couple of methods from using 'request' and instead their local variable @request:
        def params
          @request.parameters
        end
        def session
          @request.session
        end
      end
    end
  end
end
