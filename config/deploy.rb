# config valid only for current version of Capistrano
lock '3.5.0'

set :use_sudo, true
set :application, 'auto_deploy'
set :repo_url, 'git@github.com:elvis460/auto_deploy.git'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'

# Default value for :scm is :git
set :scm, :git

# Slack notifications setup
require 'slack-notifier'
set :slack_url, 'https://hooks.slack.com/services/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'
set :slack_channel, '#deploy'
set :slack_username, 'DeployBot'
set :slack_emoji, ':ghost:'
set :slack_user, `git config --get user.name`.chomp
set :slack_client, Slack::Notifier.new(
  fetch(:slack_url),
  channel: fetch(:slack_channel),
  username: fetch(:slack_username),
  icon_emoji: fetch(:slack_emoji),
)


# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')

# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 5

namespace :deploy do

  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute "sudo service apache2 restart"
    end
  end
  task :default do
    update
    restart 
  end
  # after :restart, :clear_cache do
  #   on roles(:web), in: :groups, limit: 3, wait: 10 do
  #     execute "sudo service apache2 restart"
  #     # Here we can do anything such as:
  #     # within release_path do
  #     #   execute :rake, 'cache:clear'
  #     # end
  #   end
  # end
end

#slack task
namespace :slack do
  desc 'Notify slack start of deployment'
  task :deploy_start do
    set :time_started, Time.now.to_i
    fetch(:slack_client).ping '', attachments: [{
      fallback: "#{fetch(:slack_user)} starting a deploy. Stage: #{fetch(:stage)} "\
        "Revision/Branch: #{fetch(:current_revision, fetch(:branch))} "\
        "App: #{fetch(:application)}",
      title: "Deployment Starting",
      color: "#F35A00",
      fields: [
        {
          title: "User",
          value: "#{fetch(:slack_user)}",
          short: true
        },
        {
          title: "Stage",
          value: "#{fetch(:stage)}",
          short: true
        },
        {
          title: "Revision/Branch",
          value: "#{fetch(:current_revision, fetch(:branch))}",
          short: true
        },
        {
          title: "Application",
          value: "#{fetch(:application)}",
          short: true
        }
      ]
    }]
  end

  desc 'Notify slack completion of deployment'
  task :deploy_complete do
    set :time_finished, Time.now.to_i
    elapsed = Integer(fetch(:time_finished) - fetch(:time_started))
    fetch(:slack_client).ping '', attachments: [{
      fallback: "Revision #{fetch(:current_revision, fetch(:branch))} of "\
        "#{fetch(:application)} deployed to #{fetch(:stage)} by #{fetch(:slack_user)} "\
        "in #{elapsed} seconds.",
      title: 'Deployment Complete',
      color: "#7CD197",
      fields: [
        {
          title: "User",
          value: "#{fetch(:slack_user)}",
          short: true
        },
        {
          title: "Stage",
          value: "#{fetch(:stage)}",
          short: true
        },
        {
          title: "Revision/Branch",
          value: "#{fetch(:current_revision, fetch(:branch))}",
          short: true
        },
        {
          title: "Application",
          value: "#{fetch(:application)}",
          short: true
        },
        {
          title: "Duration",
          value: "#{elapsed} seconds",
          short: true
        }
      ]
    }]
  end

  desc 'Notify slack of a failure in deployment'
  task :deploy_failed do
    fetch(:slack_client).ping "Deploy Failed!", attachments: [{
      fallback: "#{fetch(:stage)} deploy of #{fetch(:application)} "\
        "with revision/branch #{fetch(:current_revision, fetch(:branch))} failed",
      title: "Deployment Failed",
      text: "#{fetch(:stage)} deploy of #{fetch(:application)} "\
        "with revision/branch #{fetch(:current_revision, fetch(:branch))} failed",
      color: "#FF0000",
      fields: [
        {
          title: "User",
          value: "#{fetch(:slack_user)}",
          short: true
        },
        {
          title: "Stage",
          value: "#{fetch(:stage)}",
          short: true
        },
        {
          title: "Revision/Branch",
          value: "#{fetch(:current_revision, fetch(:branch))}",
          short: true
        },
        {
          title: "Application",
          value: "#{fetch(:application)}",
          short: true
        }
      ]
    }]
  end

  desc 'Notify slack of Rails Cache clearing'
  task :rails_cache_cleared do
    fetch(:slack_client).ping '', attachments: [{
      fallback: "Rails cache cleared on #{fetch(:stage)}",
      text: "Rails cache cleared on #{fetch(:stage)}",
      color: "#7CD197"
    }]
  end
end

