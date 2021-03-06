module Dorsale
  module SmallData
    class FilterStrategyByKeyValue < ::Dorsale::SmallData::FilterStrategy
      attr_reader :key

      def initialize(key = nil)
        @key = key
      end

      def apply(query, value)
        query.where("#{key} = ?", value)
      end
    end # FilterStrategy
  end # SmallData
end # Dorsale
