class Product < ApplicationRecord
  has_croppable :logo, width: 200, height: 300
end
