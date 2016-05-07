class Dorsale::ES::SearchBuilder
  # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html#_reserved_characters
  RESERVED_CHARACTERS = %w(+ - = && || > < ! ( ) { } [ ] ^ " ~ * ? : \ /)

  attr_accessor :filters, :keywords, :sort, :page, :per_page

  def initialize(options = {})
    self.filters  = options.delete(:filters)
    self.keywords = options.delete(:keywords)
    self.sort     = options.delete(:sort)
    self.page     = options.delete(:page)
    self.per_page = options.delete(:per_page)

    if options.any?
      raise ArgumentError, "Invalid option(s): #{options.keys.join(", ")}."
    end
  end

  def keywords=(keywords)
    return if keywords.blank?

    if complex_query?(keywords)
      @keywords = keywords
    else
      @keywords = normalize_keywords(keywords)
    end
  end

  def keywords
    @keywords ||= "*"
  end

  def sort
    @sort ||= "_score"
  end

  def filters=(filters)
    return if filters.blank?

    @filters = []

    filters.map do |key, value|
      next if key.nil?   || key.to_s.blank?
      next if value.nil? || value.to_s.blank?

      @filters << normalize_filter(key, value)
    end
  end

  def filters
    @filters ||= []
  end

  def page
    @page ||= 1
  end

  def per_page
    @per_page ||= 100
  end

  def es_query_string
    @es_query_string ||= (filters + [keywords]).map { |e| "(#{e})" }.join(" AND ")
  end

  def es_options
    @es_options ||= {sort: sort}
  end

  private

  def complex_query?(keywords)
    RESERVED_CHARACTERS.any? { |c| keywords.include?(c) } || keywords.match(/(AND|OR|NOT)/)
  end

  def normalize_keywords(keywords)
    keywords.to_s.downcase.split(" ").reverse.each_with_index.map do |keyword, index|
      keyword = ActiveSupport::Inflector.transliterate(keyword)
      index   = index+1

      "*#{keyword}*^#{index}"
    end.reverse.join(" OR ")
  end

  def normalize_filter(key, value)
    if value.is_a?(Time)
      value = value.utc.to_date.to_s
    else
      value = value.to_s
    end

    if value.match(/\A[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{2,4}\z/)
      value = value.split("/").reverse.join("-")
    end

    if value == "_missing_" || value == "_null_"
      key = key.chomp(":")
      return "_missing_:#{key}"
    end

    if value == "_exists_"  || value == "_not_null_"
      key = key.chomp(":")
      return "_exists_:#{key}"
    end

    if value == "_blank_"
      return "#{key}(-/.+/)"
    end

    if value == "_not_blank_"
      return "#{key}(/.+/)"
    end

    value = value.gsub /_today_/ do |m|
      Time.now.utc.to_date.to_s
    end

    value = value.gsub /_(yesterday|tomorrow)_/ do |m|
      Time.now.utc.send($~[1]).to_date.to_s
    end

    value = value.gsub /_this_(week|month|year)_/ do |m|
      date1 = Time.now.utc.to_date.send("beginning_of_#{$~[1]}")
      date2 = Time.now.utc.to_date.send("end_of_#{$~[1]}")
      "[#{date1} TO #{date2}]"
    end

    value = value.gsub /_next_(week|month|year)_/ do |m|
      date1 = Time.now.utc.to_date.send("beginning_of_#{$~[1]}") + 1.send($~[1])
      date2 = Time.now.utc.to_date.send("end_of_#{$~[1]}")       + 1.send($~[1])
      "[#{date1} TO #{date2}]"
    end

    value = value.gsub /_last_(week|month|year)_/ do |m|
      date1 = Time.now.utc.to_date.send("beginning_of_#{$~[1]}") - 1.send($~[1])
      date2 = Time.now.utc.to_date.send("end_of_#{$~[1]}")       - 1.send($~[1])
      "[#{date1} TO #{date2}]"
    end

    "#{key}#{value}"
  end

end
