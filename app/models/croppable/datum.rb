module Croppable
  class Datum < ApplicationRecord
    belongs_to :croppable, polymorphic: true
  end
end
