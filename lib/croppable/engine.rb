require "croppable/model"
require "croppable/param"

module Croppable
  class Engine < ::Rails::Engine
    isolate_namespace Croppable

    ActiveSupport.on_load(:active_record) do
      include Croppable::Model
    end

    ActiveSupport.on_load(:action_controller_base) do
      helper Croppable::Engine.helpers

      include CleanCroppableParams
    end

    initializer "croppable.assets.precompile" do
      config.after_initialize do |app|
        if app.config.respond_to?(:assets)
          app.config.assets.precompile += %w( croppable.js croppable.css  )
        end
      end
    end

  end
end
