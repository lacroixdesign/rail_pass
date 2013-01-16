require "rails/generators"
require "bundler"

module RailPass
  module Generators
    class InstallGenerator < Rails::Generators::Base
      DIRECTORIES = %w(app public spec vendor)
      FILES_TO_REMOVE = %w(README.rdoc public/index.html public/500.html public/422.html app/assets/images/rails.png app/assets/javascripts/application.js app/assets/javascripts/application.js.coffee app/assets/stylesheets/application.css app/assets/stylesheets/application.css.scss app/views/layouts/application.html.erb app/helpers/application_helper.rb test/ vendor/plugins/)

      source_root File.join(File.dirname(__FILE__), '../templates')

      desc "Adds files, gems, and config settings for Rail Pass"

      # Options
      # 
      class_option :deployment, :type => :string, :default => "heroku", :banner => "NAME",
                   :desc => "Deployment method: 'heroku' or 'capistrano'", :aliases => "-d"
      class_option :database, :type => :string, :default => "postgresql", :banner => "NAME",
                   :desc => "Database option: 'postgresql' or 'mongodb'", :aliases => "-b"
      class_option :'app-server', :type => :string, :default => "unicorn", :banner => "NAME",
                   :desc => "Database option: 'unicorn', 'puma', or 'thin'", :aliases => "-a"

      # Warn about destructive changes & confirm
      def shit_gonna_get_crazy
        accept = ask("\n#{set_color(set_color("[?]", Thor::Shell::Color::ON_BLACK), Thor::Shell::Color::RED)} These changes are #{set_color("VERY DESTRUCTIVE", Thor::Shell::Color::RED)} and only intended for #{set_color("brand-new projects", Thor::Shell::Color::BLUE)}. Proceeding with the installation will wipe out large portions of an existing project. Type 'yes' to continue, anything else to cancel.\n:")
        exit unless accept == "yes"
      end

      # Add necessary gems
      # 
      def add_gems
        gem_group :development do
          gem "quiet_assets"
          gem "letter_opener"
          gem "thin"
          gem "awesome_print"
          gem "hirb"
          gem "better_errors"
          gem "binding_of_caller"
          gem "pry"
        end
        gem_group :development, :test do
          gem "rspec-rails"
          gem "database_cleaner"
        end
        gem_group :test do
          gem "capybara"
          gem "shoulda-matchers"
          gem "spork-rails"
        end
        gem "exception_notification", "2.6.1"
        gem "haml-rails"
        gem "boarding_pass"
        gem "foreman"

        if options[:database] == "mongodb"
          gem "bson_ext"
          gem "mongoid"
        else
          gem "pg",        group: :production
          gem "sqlite3",   group: :development
          gem "rails-erd", group: :development
        end

        if options[:'app-server'] == "puma"
          gem "puma"
        elsif options[:'app-server'] == "thin"
          gem "thin"
        else
          gem "unicorn"
        end

        if options[:deployment] == "capistrano"
          gem "capistrano"
        else
          gem "newrelic_rpm"
        end
        # inside Rails.root do
        #   run "bundle install"
        # end
        Bundler.with_clean_env do
          run "bundle install"
        end
      end

      # Delete files on first-run
      # 
      def remove_files
        FILES_TO_REMOVE.each do |file|
          remove_file file
        end
      end

      # Add default files & resources
      # 
      def add_files
        DIRECTORIES.each do |dir|
          directory dir, dir
        end
        create_file ".rspec", "--color"
        copy_file "config/initializers/dev_environment.rb"
      end

      # Application configuration
      # 
      def application_configuration
        # Routes
        route 'mount RailPass::Engine, :at => "styleguide"'
        route 'root :to => "pages#index"'
        # Time zone
        gsub_file 'config/application.rb', /# config.time_zone = '.+'/ do
          "config.time_zone = \"Central Time (US & Canada)\""
        end
        # Email - Development
        inject_into_class "config/environments/development.rb", "Application" do
          dev_email = <<-eos.gsub(/^ {10}/,'')
          # Open emails in browser
          # 
          config.action_mailer.delivery_method = :letter_opener
          # config.action_mailer.default_url_options = { host: "localhost:3000" }  # FIXME replace with correct :host
          eos
          dev_email
        end
        # Render 404
        inject_into_file "app/controllers/application_controller.rb", :before => "end" do
          render_error = <<-eos.gsub(/^ {10}/,'')
          def render_404
            render "errors/404", status: :not_found
          end
          eos
          render_error
        end
        # Assets to precompile
        gsub_file 'config/environments/production.rb', /# config.assets.precompile.*/ do
          "config.assets.precompile += %w( responsive.js html5.js polyfills.js )"
        end
        %w(config/initializers/dev_environment.rb .powder).each do |ignored|
          append_file ".gitignore", ignored
        end
      end

      # Deployment configuration
      # 
      def configure_deployment
        if options[:deployment] == "capistrano"
          %w(Capfile config/deploy.rb).each do |file|
            copy_file file
          end
          directory "config/recipes"
        else
          %w(Procfile config/newrelic.yml config/initializers/new_relic.rb).each do |file|
            copy_file file
          end
          if options[:'app-server'] == "unicorn"
            copy_file "config/unicorn.rb"
          end
          # Heroku config for asset compiling, compression, and caching
          inject_into_class "config/application.rb", "Application" do
            compile_assets_config  = "# Enable compiling assets on deploy for Heroku\n"
            compile_assets_config += "config.assets.initialize_on_precompile = false"
            compile_assets_config
          end
          inject_into_file "config.ru", :before => "run " do
            "use Rack::Deflater\n"
          end
          cache_assets_config  = "config.serve_static_assets  = true\n"
          cache_assets_config += "config.static_cache_control = \"public, max-age=31536000\""
          gsub_file 'config/environments/production.rb', /config.serve_static_assets.*/, cache_assets_config
          # Email via SendGrid
          inject_into_class "config/environments/development.rb", "Application" do
            production_email = <<-eos.gsub(/^ {10}/,'')
            # Sending Email :: SendGrid
            # 
            # config.action_mailer.default_url_options = { host: "EXAMPLE.COM" }  # FIXME replace with proper :host
            config.action_mailer.delivery_method = :smtp
            config.action_mailer.smtp_settings = {
              :address        => 'smtp.sendgrid.net',
              :port           => '587',
              :authentication => :plain,
              :user_name      => ENV['SENDGRID_USERNAME'],
              :password       => ENV['SENDGRID_PASSWORD'],
              :domain         => 'heroku.com'
            }
            eos
            production_email
          end
        end
      end

      # Database configuration
      # 
      def configure_database
        if options[:database] == "mongodb"
          remove_file "config/database.yml"
          generate "mongoid:config"
          gsub_file 'config/application.rb', /require 'rails\/all'/ do
            mongo_railties = <<-eos.gsub(/^ {10}/,'')
            require "action_controller/railtie"
            require "action_mailer/railtie"
            require "active_resource/railtie"
            require "sprockets/railtie"
            require "rails/test_unit/railtie"
            eos
            mongo_railties
          end
          gsub_file 'config/application.rb', "config.active_record.whitelist_attributes = true" do
            "# config.active_record.whitelist_attributes = true"
          end
          gsub_file 'config/environments/development.rb', "config.active_record.auto_explain_threshold_in_seconds = 0.5" do
            "# config.active_record.auto_explain_threshold_in_seconds = 0.5"
          end
          gsub_file 'config/environments/development.rb', "config.active_record.mass_assignment_sanitizer = :strict" do
            "# config.active_record.mass_assignment_sanitizer = :strict"
          end
        end
      end

    end
  end
end
