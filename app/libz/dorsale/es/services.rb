module Dorsale::ES::Services
  attr_accessor :client, :default_index, :default_settings

  def self.client
    @client ||= Elasticsearch::Client.new(log: false)
  end

  def self.default_index
    @default_index ||= "#{Rails.application.class.parent_name}_#{Rails.env}".downcase
  end

  def self.default_settings
    @default_settings ||= {
      :analysis => {
        :analyzer => {
          :default => {
            :tokenizer  => "standard",
            :filter     => ["lowercase", "asciifolding"]
          },
        },
      },
    }
  end

  def self.index_exists?(index = default_index)
    client.indices.exists?(index: index)
  end

  def self.create_index!(index = default_index)
    client.indices.create(index: index, body: {settings: default_settings})
  end

  def self.delete_index!(index = default_index)
    client.indices.delete(index: index) if index_exists?(index)
  end

  def self.configure_index!(index = default_index)
    client.indices.close(index: index)
    client.indices.put_settings(index: index, body: default_settings)
    client.indices.open(index: index)
  end

  def self.create_or_reconfigure_index!(index = default_index)
    if index_exists?(index)
      configure_index!(index)
    else
      create_index!(index)
    end
  end

  def self.reset_all_models!
    delete_index!
    create_index!

    Rails.application.eager_load!
    models = ObjectSpace.each_object(::Class).select { |klass| klass < ActiveRecord::Base }

    models.each do |model|
      model.__elasticsearch__.import if model.respond_to?(:__elasticsearch__)
    end
  end

end
