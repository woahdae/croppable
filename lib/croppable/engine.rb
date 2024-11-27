require "croppable/model"

module Croppable
  class Engine < ::Rails::Engine
    isolate_namespace Croppable
    config.eager_load_namespaces << Croppable

    config.autoload_once_paths = %W(
      #{root}/app/helpers
      #{root}/app/models
      #{root}/app/controllers
      #{root}/app/controllers/concerns
    )

    initializer "croppable.helper" do
      ActiveSupport.on_load(:action_controller_base) do
        helper Croppable::Engine.helpers
      end
    end

    initializer "croppable.assets.precompile" do
      config.after_initialize do |app|
        if app.config.respond_to?(:assets)
          app.config.assets.precompile += %w( croppable.js croppable.esm.js croppable.css  )
        end
      end
    end
  end
end
