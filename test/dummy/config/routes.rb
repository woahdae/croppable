Rails.application.routes.draw do
  resources :products
  mount Croppable::Engine => "/croppable"
end
