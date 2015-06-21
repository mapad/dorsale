module Dorsale
  module Elasticsearch
    module Helper
      def es_sortable_column(name, new_column = name)
        current_column, current_order = params[:sort].to_s.split(":")

        if current_column == new_column
          new_order = current_order == "asc" ? "desc" : "asc"
          arrow     = current_order == "desc" ? "↑" : "↓"
          name      = "#{name} #{arrow}"
        else
          new_order = "asc"
        end

        url = request.GET.merge(sort: "#{new_column}:#{new_order}")
        link_to name, url
      end
    end
  end
end
