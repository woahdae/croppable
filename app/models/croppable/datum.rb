module Croppable
  class Datum < ApplicationRecord
    belongs_to :croppable, polymorphic: true

    attribute :background_color, :string, default: '#FFFFFF'
  end
end
