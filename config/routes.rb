Rails.application.routes.draw do
  get '/', to: 'media#index', as: :media
end
