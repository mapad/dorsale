module Dorsale::ES::ViewHelper
  def es_sortable_column(name, column = name)
    active_column, current_order = params[:sort].to_s.split(":")

    if active_column == column.to_s
      new_order = current_order == "asc" ? "desc" : "asc"
      arrow     = current_order == "desc" ? "↑" : "↓"
      name      = "#{name} #{arrow}"
    else
      new_order = "asc"
    end

    url   = url_for request.GET.merge(sort: "#{column}:#{new_order}")
    klass = "sort #{current_order}"

    link_to(name, url, class: klass)
  end
end
