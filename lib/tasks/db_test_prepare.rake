namespace :db do
  namespace :test do
    
    desc 'after completing db:test:prepare load probe configurations'
    task :prepare do
      ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'])
      Rake::Task['db:backup:load_probe_configurations'].invoke
      Rake::Task['db:backup:load_ri_grade_span_expectations'].invoke
      Rake::Task['app:jnlp:generate_maven_jnlp_resources'].invoke('false')
      require File.expand_path('../../../spec/spec_helper.rb', __FILE__)
      Rake::Task['app:setup:create_default_users'].invoke
    end

  end
end
    