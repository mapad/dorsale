module Dorsale::ES::ControllerHelper
  def es(scope)
    keywords = params[:q]
    filters  = params[:filters]
    sort     = params[:sort]
    page     = params[:page]
    per_page = self.per_page rescue 100

    if keywords.blank? && filters.blank? & sort.blank?
      return scope.page(page).per(per_page)
    end

    begin
      scope.es(
        :keywords => keywords,
        :filters  => filters,
        :sort     => sort,
        :page     => page,
        :per_page => per_page,
      )
    rescue StandardError => e
      es_exception(e)
      scope.page(page).per(per_page)
    end
  end

  def es_exception(e)
    if Rails.env.development? || Rails.env.test?
      raise e
    else
      flash.now[:alert] = t("elasticsearch.error")
    end
  end

end
