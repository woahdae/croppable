class Product < ApplicationRecord
  include Croppable::Model

  has_croppable :logo, width: 200, height: 300
end
