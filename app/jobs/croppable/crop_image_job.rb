require "croppable/crop"

module Croppable
  class CropImageJob < ApplicationJob
    queue_as :default

    def perform(model, croppable_name, uploaded_file: nil)
      Croppable::Crop.new(
        model, croppable_name,
        uploaded_file: uploaded_file
      ).perform()
    end
  end
end
