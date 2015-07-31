set :domain, '123.59.11.102'
set :branch, 'production'
set :deploy_to, "#{apps_path}/test_rails4"

task :environment do 
	invoke :'rvm:use[ruby-2.2.1@default]'
end