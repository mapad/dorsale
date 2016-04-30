Rails.application.routes.draw do
  devise_for :users

  root "home#home"

  get "/dummy/:action" => "dummy"

  mount Dorsale::Engine => "/dorsale"
end
