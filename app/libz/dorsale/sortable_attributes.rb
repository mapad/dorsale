module Dorsale::SortableAttributes
  def method_missing(m, *args)
    if m.to_s.match(/^sortable_(.+)/)
      send($~[1], *args).to_s.parameterize.gsub("-", "_")
    else
      super(m, *args)
    end
  end
end
