module Dorsale
  module Elasticsearch
    module ControllerHelper
      private

      def es(model)
        query    = params[:q]
        sort     = params[:sort]
        page     = params[:page]
        per_page = self.per_page rescue 100

        if query.blank? && sort.blank?
          return model.page(page).per(per_page)
        end

        query = "*" if query.blank?

        # "Magic" keywords
        if query.is_a?(String)
          query = query.gsub /_(yesterday|today|tomorrow)_/ do |m|
            date = Date.send($~[1]).to_s
            "[#{date} TO #{date}]"
          end

          query = query.gsub /_this_(week|month|year)_/ do |m|
            date1 = Date.today.send("beginning_of_#{$~[1]}")
            date2 = Date.today.send("end_of_#{$~[1]}")
            "[#{date1} TO #{date2}]"
          end

          query = query.gsub /_next_(week|month|year)_/ do |m|
            date1 = Date.today.send("beginning_of_#{$~[1]}") + 1.send($~[1])
            date2 = Date.today.send("end_of_#{$~[1]}")       + 1.send($~[1])
            "[#{date1} TO #{date2}]"
          end

          query = query.gsub /_last_(week|month|year)_/ do |m|
            date1 = Date.today.send("beginning_of_#{$~[1]}") - 1.send($~[1])
            date2 = Date.today.send("end_of_#{$~[1]}")       - 1.send($~[1])
            "[#{date1} TO #{date2}]"
          end
        end

        # Add wildcares around words on simple search
        if query == query.parameterize(" ")
          query = query.split(" ").map{ |w| "*#{w}*" }.join(" ")
        end

        ap query
        ap sort

        model.search(query, sort: sort).page(page).per(per_page).records
      end
    end
  end
end
