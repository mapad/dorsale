module Dorsale
  module AllHelpers
    include ::ActionView::Helpers::NumberHelper

    include ::Dorsale::ButtonHelper
    include ::Dorsale::CommentsHelper
    include ::Dorsale::ContextHelper
    include ::Dorsale::FiltersHelper
    include ::Dorsale::FormHelper
    include ::Dorsale::LinkHelper
    include ::Dorsale::PaginationHelper
    include ::Dorsale::RoutesHelper
    include ::Dorsale::TextHelper
    include ::Dorsale::ES::ViewHelper

    include ::Dorsale::Alexandrie::AttachmentsHelper
    include ::Dorsale::Flyboy::ApplicationHelper
    include ::Dorsale::UsersHelper


    extend self
  end
end
