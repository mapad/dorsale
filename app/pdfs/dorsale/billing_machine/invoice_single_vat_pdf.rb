require "prawn/measurement_extensions"

module Dorsale
  module BillingMachine
    class InvoiceSingleVatPdf < Prawn::Document
      include Dorsale::Alexandrie::Prawn
      include Dorsale::AllHelpers
      include ActionView::Helpers::NumberHelper
      DEBUG = false

      GREY       = "808080"
      LIGHT_GREY = "C0C0C0"
      WHITE      = "FFFFFF"
      BLACK      = "000000"
      BLUE       = "005F9E"

      def has_advance
        @main_document.try(:advance) && @main_document.advance != 0.0
      end

      def has_discount
        @main_document.try(:commercial_discount) && @main_document.commercial_discount != 0.0
      end

      def first_column_width
        7.6.cm
      end

      def second_column_width
        2.4.cm
      end

      def third_column_width
        second_column_width
      end

      def fourth_column_width
       2.9.cm
      end

      def last_column_width
        bounds.width - first_column_width - second_column_width - third_column_width - fourth_column_width
      end

      attr_reader :main_document

      def initialize(main_document)
        super(page_size: 'A4', margin: 1.cm)
        setup
        @main_document = main_document
        @id_card       = main_document.id_card
      end

      def header_height
        9.cm
      end

      def middle_height
        15.cm
      end

      def footer_height
        4.cm
      end

      def logo_height
        3.2.cm
      end

      def build
        repeat :all do
          build_header
          build_footer
        end
        build_middle
        build_page_numbers
      end

      def setup
        font_root = ::Dorsale::Engine.root.join("app/assets/fonts")
        font_families.update(
          "BryantPro" => {
            normal: "#{font_root}/BryantPro-Regular.ttf",
            bold:   "#{font_root}/BryantPro-Bold.ttf",
          }
        )

        font("BryantPro")
        font_size 10
      end

      def build_header
        bounding_box [0, bounds.top], width: bounds.width, height: header_height do
          draw_bounds_debug
          build_title
          build_logo
          build_contact
          build_subject
          build_customer
        end
      end

      def build_title
        top    = bounds.top - 1.5.cm
        left   = bounds.left
        width  = bounds.width
        height = 1.cm
        bounding_box [left, top], width: width, height: height do
          draw_bounds_debug
          text "<b>#{main_document.t} n° #{@main_document.tracking_id}</b>", inline_format: true, size: 20, align: :center
        end
      end

      def build_logo
        width = 3.2.cm
        height = logo_height
        bounding_box [bounds.left, bounds.top], width: width, height: height do
          draw_bounds_debug
          if @main_document.id_card.logo.present?
            image @main_document.id_card.logo.path, width: (bounds.width - 1.cm)
          end
        end
      end

      def address_line
        [@id_card.address1,@id_card.address2, @id_card.zip, @id_card.city].select(&:present?).join(", ")
      end

      def build_contact
        top    = bounds.top - 4.cm
        left   = bounds.left
        width  = bounds.width / 2 - 1.1.cm
        height = 2.5.cm

        bounding_box [left, top], width: width, height: height do
          draw_bounds_debug
          font_size 8 do
          text "<b>#{@id_card.entity_name}</b>", inline_format: true if @id_card.entity_name.present?
          text "<b>#{address_line} </b>", inline_format: true
          text " "
          text "<b>#{I18n.t("pdfs.your_contact")} : #{@id_card.contact_full_name}</b>", inline_format: true if @id_card.contact_full_name.present?
          text "<b>#{I18n.t("pdfs.contact_phone")}</b>  #{@id_card.contact_phone}", inline_format: true if @id_card.contact_phone.present?
          text "<b>#{I18n.t("pdfs.contact_fax")}</b> #{@id_card.contact_fax}",   inline_format: true if @id_card.contact_fax.present?
          text "<b>#{I18n.t("pdfs.contact_email")}</b> #{@id_card.contact_email}",   inline_format: true if @id_card.contact_email.present?
          end
        end
      end

      def build_subject
        top    = bounds.top - 7.5.cm
        left   = bounds.left
        width  = bounds.width / 2 - 1.1.cm
        height = 15.mm

        bounding_box [left, top], width: width, height: height do
          draw_bounds_debug

          if @main_document.label.present?
            text "<b>#{I18n.t("pdfs.subject")}</b> #{@main_document.label}", inline_format: true
          end

          if @main_document.date.present?
            move_down 3.mm
            text "<b>#{@main_document.t :date} :</b> #{date @main_document.date}", inline_format: true
          end
        end
      end

      def build_customer
        top    = bounds.top - 4.cm
        left   = bounds.width / 2 + 1.1.cm
        width  = bounds.width / 2 - 1.1.cm
        height = 4.5.cm
        padding = 3.mm

        bounding_box [left, top], width: width, height: height do
          draw_bounds_debug
          stroke do
            fill_color LIGHT_GREY
            fill_rounded_rectangle [cursor-bounds.height,cursor], bounds.width, bounds.height, 0
            fill_color BLACK
          end


          bounding_box [bounds.left + padding, bounds.top - padding], height: bounds.height - padding, width: bounds.width - padding do
            if @main_document.customer.present?
              text @main_document.customer.name if @main_document.customer.name.present?
              text @main_document.customer.address.street if @main_document.customer.address.street.present?
              text @main_document.customer.address.street_bis if @main_document.customer.address.street_bis.present?
              text "#{@main_document.customer.address.zip} #{@main_document.customer.address.city}, #{@main_document.customer.address.country}" if @main_document.customer.address.zip.present? || @main_document.customer.address.city.present? || @main_document.customer.address.country.present?
              text "#{@main_document.customer.t :european_union_vat_number} :\n#{european_union_vat_number}" if @main_document.customer.try(:european_union_vat_number).present?
            end
          end

        end
      end

      def build_middle
        left   = bounds.left
        top    = bounds.top - header_height
        width  = bounds.width - left
        bounding_box [left, top], width: width, height: middle_height do
        build_table
        build_total
        build_payment_conditions
        build_bank_informations
        build_expiry
        build_comments
        end
      end

      def build_table
        left   = bounds.left
        top    = bounds.top
        width  = bounds.width - left

        bounding_box [left, top], width: width, height: 9.5.cm do
          repeat :all do
            float do
                table [["","","","",""]],
                    :column_widths => [first_column_width, second_column_width, third_column_width, fourth_column_width, last_column_width],
                    :cell_style => {:height => 9.5.cm} do
                      row(0).style :text_color       => BLACK
                      row(0).style :font_style       => :bold
                      column(0).style :align => :left
                      column(1..4).style :align => :right
                    end
                 end
              end
          end

        bounding_box [left, top], width: width, height: 8.8.cm do
          draw_bounds_debug
          repeat :all do
            build_line
          end
          table_products = [[I18n.t("pdfs.designation"),
            I18n.t("pdfs.quantity"),
            I18n.t("pdfs.unity"),
            I18n.t("pdfs.unit_price"),
            I18n.t("pdfs.line_total")]]


          @main_document.lines.each do |line|
            printed_quantity = number(line.quantity).gsub(",00","").gsub(".00","") if line.quantity > 0
            printed_unit_price = euros(line.unit_price) if line.unit_price > 0
            printed_line_total = euros(line.total) if line.total > 0
            table_products.push [line.label,
                printed_quantity,
                line.unit,
                printed_unit_price,
                printed_line_total,]
          end

        table table_products,
          :column_widths => [first_column_width, second_column_width, third_column_width, fourth_column_width, last_column_width],
          :header => true,
          :cell_style    => {border_width: 0} do
            row(0).font_style = :bold
            row(0).border_width = 1,
            cells.style do |c|
              c.align = c.column == 0 ? :left : :right
            end
          end
        end
      end

      def build_total

        left   = bounds.left
        top    = bounds.top - 10.3.cm
        width  = bounds.width - left

        bounding_box [left, top], width: width, height: middle_height - 9.5.cm do
          draw_bounds_debug

          table_totals = [[]]

          if has_discount
            table_totals.push ["#{I18n.t("pdfs.commercial_discount")}", "\- #{euros(@main_document.commercial_discount)}"]
          end

          table_totals.push ["#{I18n.t("pdfs.total_excluding_taxes")}", euros(@main_document.total_excluding_taxes)]

          vat_rate = number(@main_document.vat_rate)
          table_totals.push ["#{I18n.t("pdfs.vat")}#{vat_rate} %", euros(@main_document.vat_amount)]

          if has_advance
            table_totals.push ["#{I18n.t("pdfs.advance")}", euros(@main_document.advance)]
            table_totals.push ["#{I18n.t("pdfs.total_including_taxes")}", euros(@main_document.balance)]
          else
            table_totals.push ["#{I18n.t("pdfs.total_including_taxes")}", euros(@main_document.total_including_taxes)]
          end

          table table_totals,
            :column_widths => [fourth_column_width, last_column_width],
            :cell_style    => {border_width: [0, 1, 0 ,0]},
            :position      => :right do
              row(-1).style :font_style       => :bold
              column(0).padding_right = 0.2.cm
              row(-1).borders = [:top, :right]
              row(-1).border_width = 1
              cells.style do |c|
                c.align = :right
              end
            end
          stroke do
            rectangle [(bounds.right - fourth_column_width - last_column_width), bounds.top], (fourth_column_width + last_column_width), (bounds.top-cursor)
          end
        end
      end

      def build_comments
      end



      def build_payment_conditions
        top = bounds.top - 10.3.cm
        height = 1.cm
        width  = 7.5.cm

        bounding_box [bounds.left, top], height: height, width: width do
          draw_bounds_debug
          font_size 9 do
            text I18n.t("pdfs.payment_terms"), style: :bold if @main_document.payment_term.present?
            text @main_document.payment_term.try(:label)
          end
        end
      end

      def build_expiry
      end

      def build_bank_informations
        top = bounds.top - 11.5.cm
        height = 1.cm
        width  = 7.5.cm

        bounding_box [bounds.left, top], height: height, width: width do
          draw_bounds_debug
          font_size 9 do
            text "#{I18n.t("pdfs.iban")} #{@id_card.iban}" if @id_card.iban.present?
            text "#{I18n.t("pdfs.bic_swift")} #{@id_card.bic_swift}"  if @id_card.bic_swift.present?
          end
        end
      end

      def build_footer
        top = bounds.bottom + footer_height
        bounding_box [0, top], width: bounds.width, height: footer_height do

          builds_legals
          build_line
          builds_id_card_informations

        end
      end

      def builds_legals
        top = bounds.top
        height = 1.5.cm
        width  = bounds.width
        bounding_box [bounds.left, top], height: height, width: width do
          font_size 9 do
            text @id_card.custom_info_1, inline_format: true
          end
        end
      end

      def build_line
        stroke do
          horizontal_rule
          line_width 1
        end
      end

      def builds_id_card_informations
        top = bounds.top - 1.8.cm
        height = 1.1.cm
        width  = bounds.width
        tel = "#{I18n.t("pdfs.info_phone")} #{@id_card.contact_phone} - " if @id_card.contact_phone.present?
        fax = "#{I18n.t("pdfs.info_fax")} #{@id_card.contact_fax} -" if @id_card.contact_fax.present?
        email = "#{@id_card.contact_email}" if @id_card.contact_email.present?
        capital = "#{ @id_card.legal_form.to_s} #{I18n.t("pdfs.capital")} " + number_with_delimiter(@id_card.capital, :delimiter => '.').to_s + " €" if @id_card.legal_form.present? && @id_card.capital.present?
        registration = I18n.t("pdfs.registration") + @id_card.registration_city.to_s + ' ' + @id_card.registration_number.to_s if @id_card.registration_number.present?
        siret = I18n.t("pdfs.siret") + @id_card.siret.to_s if @id_card.siret.present?
        tva = I18n.t("pdfs.vat") + @id_card.intracommunity_vat.to_s if @id_card.intracommunity_vat.present?
        font_size 9 do
          text_box "#{@id_card.entity_name} #{address_line}\n#{tel} #{fax} #{email}\n#{capital} #{registration} #{siret} #{tva}",
            :at       => [bounds.left, top],
            :height   => height,
            :width    => width,
            :overflow => :shrink_to_fit
        end
      end

      def build_page_numbers
        top = bounds.bottom + footer_height - 1.8.cm
        bounding_box [0, top], height: footer_height, width: bounds.width do
          font_size 9 do
            float do
              options = {
              :align => :right,
              :start_count_at => 1
              }
              number_pages "page <page>/<total>", options
            end
          end
        end
      end

      def draw_bounds_debug
        transparent(0.5) { stroke_bounds } if DEBUG
      end
    end
  end
end
