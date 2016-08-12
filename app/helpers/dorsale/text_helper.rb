module Dorsale
  module TextHelper
    include ::ActionView::Helpers::TextHelper
    include ::ActionView::Helpers::SanitizeHelper

    def euros(n)
      currency(n, "€")
    end

    def currency(n, u)
      return if n.nil?

      I18n.t("number.currency.format.format")
        .gsub("%n", number(n))
        .gsub("%u", u)
        .gsub(" ", "\u00A0")
    end

    def percentage(n)
      return if n.nil?

      (number(n) + " %").gsub(" ", "\u00A0")
    end

    def number(n)
      return if n.nil?

      opts = {}

      if n.class.to_s.match(/Float|Decimal/i)
        opts[:precision] = 2
      else
        opts[:precision] = 0
      end

      opts[:delimiter] = I18n.t("number.format.delimiter")
      opts[:separator] = I18n.t("number.format.separator")

      number_with_precision(n, opts).gsub(" ", "\u00A0")
    end

    def date(d)
      return if d.nil?
      I18n.l(d)
    end

    def hours(n)
      return if n.nil?

      number = number_with_precision(n, precision: 2)
      text   = I18n.t("datetime.prompts.hour").downcase
      text   = text.pluralize if n > 1
      "#{number} #{text}"
    end

    def text2html(str)
      return if str.to_s.blank?

      str = str.gsub("\r", "").strip
      strip_tags(str).gsub("\n", "<br />").html_safe
    end

    def info(object, attribute, text_or_options = nil, options = {})
      if text_or_options.is_a?(Hash)
        text    = nil
        options = text_or_options
      else
        text = text_or_options
      end

      label       = options[:label]     || object.t(attribute)
      tag         = options[:tag]       || :div
      separator   = options[:separator] || " : "
      helper      = options[:helper]
      i18n_key    = "#{object.class.to_s.tableize.singularize}/#{attribute}"
      nested      = I18n.t("activerecord.attributes.#{i18n_key}").is_a?(Hash)
      klass       = object.is_a?(Class) ? object : object.class
      object_type = klass.to_s.split("::").last.underscore

      value = text
      value = object.public_send(attribute)     if value.nil?
      value = t("yes")                          if value === true
      value = t("no")                           if value === false
      value = object.t("#{attribute}.#{value}") if value.nil? && nested
      value = send(helper, value)               if helper
      value = number(value)                     if value.is_a?(Numeric)
      value = l(value)                          if value.is_a?(Time)
      value = l(value)                          if value.is_a?(Date)
      value = value.to_s

      html_label     = content_tag(:strong, class: "info-label") { label }
      span_css_class = "info-value #{object_type}-#{attribute}"
      html_value     = content_tag(:span, class: span_css_class) { value }

      content_tag(tag, class: "info") do
        [html_label, separator, html_value].join.html_safe
      end
    end

  end # TextHelper
end # Dorsale
