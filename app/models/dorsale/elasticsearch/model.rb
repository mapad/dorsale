class BigDecimal
  def as_json(*)
    to_f
  end
end

module Dorsale
  module Elasticsearch
    module Model
      def self.included(model)
        model.send(:include, ::Elasticsearch::Model)

        model.class_eval do
          after_commit on: [:create, :update] do
            __elasticsearch__.index_document
          end

          after_commit on: [:destroy] do
            __elasticsearch__.delete_document
          end

          def elasticsearch_include_relations
            belongs_to_reflections = self.class.reflections.map do |name, reflection|
              name.to_sym if reflection.macro == :belongs_to
            end

            belongs_to_reflections.compact
          end

          def elasticsearch_include_methods
            [
              :name,
            ]
          end

          def as_indexed_json(*)
            as_json(
              :include => elasticsearch_include_relations,
              :methods => elasticsearch_include_methods,
            )
          end

          def self.elasticsearch_models
            [self]
          end

          def self.search(query, options = {})
            options = {size: 100}.merge(options)

            results = __elasticsearch__.search(query, options)
            results.any?
            results
          rescue ::Exception => e
            if %w(development test).include?(Rails.env)
              raise e
            else
              where(id: nil)
            end
          end

          index_name    "#{Rails.application.class.parent_name}_#{Rails.env}".downcase
          document_type table_name

          def self.elasticsearch_reset!
            __elasticsearch__.settings(
              :analysis => {
                :analyzer => {
                  :default => {
                    :tokenizer  => "keyword",
                    :filter  => ["lowercase", "asciifolding"]
                  }
                }
              }
            )

            __elasticsearch__.create_index! force: true
            __elasticsearch__.refresh_index!
            __elasticsearch__.import
          end

        end # clas_eval
      end # self.included
    end # Model
  end # Elasticsearch
end # Dorsale
