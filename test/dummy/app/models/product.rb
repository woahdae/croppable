class Product < ApplicationRecord
  has_croppable :logo, width: 200, height: 300

  has_many :widgets, inverse_of: :product

  accepts_nested_attributes_for :widgets
end
