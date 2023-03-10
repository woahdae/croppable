# frozen_string_literal: true

require "pathname"
require "json"

module Croppable
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def install_javascript_dependencies
        destination = Pathname(destination_root)

        if Pathname(destination_root).join("package.json").exist?
          say "Installing JavaScript dependencies", :green
          run "yarn add cropperjs@next"
        end

        if (importmap_path = destination.join("config/importmap.rb")).exist?
          say "Installing JavaScript dependencies", :green
          run "bin/importmap pin cropperjs@next"
        end
      end

      def append_javascript_dependencies
        destination = Pathname(destination_root)

        if (application_javascript_path = destination.join("app/javascript/application.js")).exist?
          insert_into_file application_javascript_path.to_s, %(\nimport "croppable"\n)
        else
          say <<~INSTRUCTIONS, :green
            You must import the croppable JavaScript module in your application entrypoint.
          INSTRUCTIONS
        end

        if (importmap_path = destination.join("config/importmap.rb")).exist?
          append_to_file importmap_path.to_s, %(pin "croppable"\n)
        end
      end

      def append_css_dependencies
        destination = Pathname(destination_root)

        if (stylesheet = destination.join("app/assets/stylesheets/application.css")).exist?
          insert_into_file stylesheet, %( *= require croppable\n), before: " *= require_self"
        else
          say <<~INSTRUCTIONS, :green
            To use the Croppable gem, you must import 'croppable' in your base stylesheet.
          INSTRUCTIONS
        end
      end

      def install_active_storage
        rails_command "active_storage:install", inline: true
      end

      def create_migrations
        rails_command "croppable:install:migrations", inline: true
      end
    end
  end
end
