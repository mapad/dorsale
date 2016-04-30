class DummyModel < ActiveRecord::Base
  include Dorsale::ES::Model

  default_scope -> {
    order(id: :desc)
  }
end
