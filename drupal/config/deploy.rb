set :stages, %w(production staging development)
set :default_stage, "development"
require 'capistrano/ext/multistage'

set :application, "app"
set :repository,  "drupal"
set :scm, :none
set :deploy_via, :copy
set :user, "#{application}"
set :group, "www-data"
set :use_sudo, false
set :current_dir, "htdocs"

set :branch, ENV["WERCKER_GIT_BRANCH"]
set :deploy_to, "/home/#{application}/www/#{branch}"
set :shared_root, "/home/#{application}/www/shared"
set(:app_path) { "#{latest_release}" }

ssh_options[:keys] = [ENV["CAP_PRIVATE_KEY"]]

after "deploy:update_code", "drupal:symlink_shared", "drush:site_offline", "drush:updatedb", "drush:cache_clear", "drush:site_online"

# Override default tasks which are not relevant to a non-rails app.
namespace :deploy do
  task :migrate do
    puts "    Not doing migrate because we are not a Rails application."
  end
  task :finalize_update do
    puts "    Not doing finalize_update because we are not a Rails application."
  end
  task :start do ; end
  task :stop do ; end
  task :restart do ; end
end

namespace :drupal do
  desc "Symlink settings and files to shared directory. This allows the settings.php and \
and sites/default/files directory to be correctly linked to the shared directory on a new deployment."
  task :symlink_shared do
    ["files", "private", "settings.php"].each do |asset|
      run "rm -rf #{app_path}/sites/default/#{asset}"
    end

    run "ln -nfs #{shared_root}/files #{app_path}/sites/default/files"
    run "ln -nfs #{shared_root}/private #{app_path}/sites/default/private"
    run "ln -nfs #{shared_path}/settings.php #{app_path}/sites/default/settings.php"
  end
end

namespace :drush do

  desc "Backup the database"
  task :backupdb, :on_error => :continue do
    run "drush -r #{app_path} bam-backup"
  end

  desc "Run Drupal database migrations if required"
  task :updatedb, :on_error => :continue do
    run "drush -r #{app_path} updatedb -y"
  end

  desc "Clear the drupal cache"
  task :cache_clear, :on_error => :continue do
    run "drush -r #{app_path} cc all"
  end

  desc "Set the site offline"
  task :site_offline, :on_error => :continue do
    run "drush -r #{app_path} vset site_offline 1 -y"
    run "drush -r #{app_path} vset maintenance_mode 1 -y"
  end

  desc "Set the site online"
  task :site_online, :on_error => :continue do
    run "drush -r #{app_path} vset site_offline 0 -y"
    run "drush -r #{app_path} vset maintenance_mode 0 -y"
  end
end
