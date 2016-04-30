class DummyModelsAddFields < ActiveRecord::Migration
  def change
    add_column :dummy_models, :string_field,   :string
    add_column :dummy_models, :text_field,     :text
    add_column :dummy_models, :integer_field,  :integer
    add_column :dummy_models, :decimal_field,  :decimal
    add_column :dummy_models, :date_field,     :date
    add_column :dummy_models, :datetime_field, :datetime
    add_column :dummy_models, :boolean_field,  :boolean
  end
end
