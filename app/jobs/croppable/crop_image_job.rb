require "croppable/crop"

module Croppable
  class CropImageJob < ApplicationJob
    queue_as :default

    def perform(model, croppable_name)
      Croppable::Crop.new(model, croppable_name).perform()
    end
  end
end
