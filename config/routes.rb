Dorsale::Engine.routes.draw do
  resources :comments, only: [:create, :edit, :update, :destroy]

  resources :users, except: [:destroy]

  namespace :small_data do
    resources :filters, only: [:create]
  end

  namespace :alexandrie do
    resources :attachments, only: [:create, :edit, :update, :destroy]
  end

  namespace :flyboy do
    resources :folders do
      member do
        patch :open
        patch :close
      end
    end

    resources :tasks do
      get :summary, on: :collection
      member do
        patch :complete
        patch :snooze
      end
    end

    resources :task_comments, only: [:create]
  end

  namespace :billing_machine do
    resources :invoices, except: [:destroy] do
      member do
        get :copy
        patch :pay
        match :email, via: [:get, :post]
      end
    end

    resources :quotations do
      post :copy, on: :member
      get :create_invoice, on: :member
    end
  end

  namespace :customer_vault do
    resources :corporations, except: [:index] do
      resources :links, except: [:index]
    end

    resources :individuals, :except => [:index] do
      resources :links, except: [:index]
    end

    namespace :people do
      get "/", action: "index"
      get :activity
      get :list
    end
  end

  namespace :expense_gun do
    resources :expenses, except: [:destroy] do
      resources :expense_lines
      member do
        %w(submit accept refuse cancel).map { |action| patch action }
      end
    end

    get "/expenses/state/:state" => "expenses#index"
    get "/expenses/state/:state/page/:page" => "expenses#index"

    get "/" => redirect{ ExpenseGun::Engine.routes.url_helpers.expenses_path }
  end
end
