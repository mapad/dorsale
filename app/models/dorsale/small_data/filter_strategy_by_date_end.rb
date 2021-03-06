module Dorsale
  module SmallData
    class FilterStrategyByDateEnd < ::Dorsale::SmallData::FilterStrategyByKeyValue
      def apply(query, value)
        value = Time.parse(value).end_of_day
        query.where("#{key} <= ?", value)
      end
    end # FilterStrategy
  end # SmallData
end # Dorsale
