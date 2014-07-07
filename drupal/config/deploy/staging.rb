server "stage.com", :app, :web
set :user, "www-data"
set :deploy_to, "/var/www/#{application}/staging"
set :shared_root, "/var/www/#{application}/shared"
