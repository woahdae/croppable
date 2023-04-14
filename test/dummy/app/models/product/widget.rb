class Product::Widget < ApplicationRecord
  include Croppable::Model

  has_croppable :image, width: 300, height: 300

  belongs_to :product, inverse_of: :widgets
end
