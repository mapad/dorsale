module Dorsale
  module BillingMachine
    class InvoiceMultipleVatPdf < ::Dorsale::BillingMachine::InvoiceSingleVatPdf

      def first_column_width
        6.4.cm
      end

      def second_column_width
        2.cm
      end

      def third_column_width
        second_column_width
      end

      def fourth_column_width
       second_column_width
      end

      def fifth_column_width
        2.9.cm
      end

      def last_column_width
        bounds.width - first_column_width - second_column_width - third_column_width - fourth_column_width - fifth_column_width
      end

      def build_table
        left   = bounds.left
        top    = bounds.top
        width  = bounds.width - left

        bounding_box [left, top], width: width, height: 9.5.cm do
          repeat :all do
            float do
                table [["","","","","",""]],
                    :column_widths => [first_column_width, second_column_width, third_column_width, fourth_column_width, fifth_column_width, last_column_width],
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
            I18n.t("pdfs.tax"),
            I18n.t("pdfs.unit_price"),
            I18n.t("pdfs.line_total")]]


          @main_document.lines.each do |line|
            printed_quantity = number(line.quantity).gsub(",00","").gsub(".00","") if line.quantity > 0
            printed_unit_price = euros(line.unit_price) if line.unit_price > 0
            printed_vat_rate = percentage(line.vat_rate) if line.vat_rate > 0
            printed_line_total = euros(line.total) if line.total > 0
            table_products.push [line.label,
                printed_quantity,
                line.unit,
                printed_vat_rate,
                printed_unit_price,
                printed_line_total,]
          end

        table table_products,
          :column_widths => [first_column_width, second_column_width, third_column_width, fourth_column_width, fifth_column_width, last_column_width],
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

          table_totals.push ["#{I18n.t("pdfs.vat_amount")}", euros(@main_document.vat_amount)]

          if has_advance
            table_totals.push ["#{I18n.t("pdfs.advance")}", euros(@main_document.advance)]
            table_totals.push ["#{I18n.t("pdfs.total_including_taxes")}", euros(@main_document.balance)]
          else
            table_totals.push ["#{I18n.t("pdfs.total_including_taxes")}", euros(@main_document.total_including_taxes)]
          end

          table table_totals,
            :column_widths => [fifth_column_width , last_column_width],
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
            rectangle [(bounds.right - fifth_column_width - last_column_width), bounds.top], (fifth_column_width + last_column_width), (bounds.top-cursor)
          end
        end
      end

    end
  end
end
