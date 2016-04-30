require "elasticsearch/model"

# Do not pollute models
Elasticsearch::Model::METHODS.clear

module Dorsale::ES::Model
  extend ActiveSupport::Concern

  included do
    include ::Elasticsearch::Model

    __elasticsearch__.index_name    Dorsale::ES::Services.default_index
    __elasticsearch__.document_type table_name

    Dorsale::ES::Services.create_or_reconfigure_index!(__elasticsearch__.index_name)

    def es_index_document!
      __elasticsearch__.index_document
    end

    def es_delete_document!
      __elasticsearch__.delete_document
    end

    after_commit :es_index_document!,  on: [:create, :update]
    after_commit :es_delete_document!, on: [:destroy]
  end

  class_methods do
    def es(*args)
      search = Dorsale::ES::SearchBuilder.new(*args)

      Rails.logger.debug "Dorsale::ES search :"
      Rails.logger.debug "Query string : #{search.es_query_string}"
      Rails.logger.debug "Options : #{search.es_options}"

      __elasticsearch__
        .search(search.es_query_string, search.es_options)
        .page(search.page)
        .per(search.per_page)
        .records
        .reorder(nil)
    end

    def search(*)
      raise RuntimeError, "please use #es instead of #search"
    end
  end
end

class BigDecimal
  def as_json(*)
    to_f
  end
end
