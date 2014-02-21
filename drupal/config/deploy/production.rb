server "prod.com", :app, :web
set :user, "www-data"
set :deploy_to, "/var/www/#{application}/release"
set :shared_root, "/var/www/#{application}/shared"
