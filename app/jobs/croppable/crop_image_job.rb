require "croppable/crop"

module Croppable
  class CropImageJob < ApplicationJob
    queue_as :default
    # Sometimes the file hasn't been uploaded to storage when the job starts.
    # Default is 3s delay and 5 attempts, we'll do 1s delay & default attempts.
    retry_on ActiveStorage::FileNotFoundError, wait: 1

    def perform(model, croppable_name, uploaded_file: nil, headless: {})
      Croppable::Crop.new(
        model, croppable_name,
        uploaded_file: uploaded_file,
        headless: headless
      ).perform
    end
  end
end
