module Dorsale
  module BillingMachine
    class Invoice < ActiveRecord::Base
      self.table_name = "dorsale_billing_machine_invoices"

      belongs_to :customer, polymorphic: true
      belongs_to :payment_term
      belongs_to :id_card

      has_many :lines, inverse_of: :invoice, dependent: :destroy, class_name: ::Dorsale::BillingMachine::InvoiceLine

      accepts_nested_attributes_for :lines, allow_destroy: true

      polymorphic_id_for :customer

      validates :id_card, presence: true
      validates :date,    presence: true

      # simple_form
      validates :id_card_id, presence: true

      def initialize(*args)
        super
        assign_default_values
        self.due_date              = 30.days.from_now if due_date.nil?
        self.date                  = Date.today       if date.nil?
      end

      before_create :assign_unique_index
      before_create :assign_tracking_id
      before_validation :assign_default_values

      def assign_unique_index
        if unique_index.nil?
          self.unique_index = self.class.all.pluck(:unique_index).max.to_i.next
        end
      end

      def assign_tracking_id
        self.tracking_id = date.year.to_s + "-" + unique_index.to_s.rjust(2, "0")
      end

      def assign_default_values
        self.advance               = 0.0   if advance.nil?
        self.vat_amount            = 0.0   if vat_amount.nil?
        self.commercial_discount   = 0.0   if commercial_discount.nil?
        self.total_excluding_taxes = 0.0   if total_excluding_taxes.nil?
        self.paid                  = false if paid.nil?
      end

      before_save :update_totals

      def update_totals
        assign_default_values
        lines_sum = lines.map(&:total).sum

        self.total_excluding_taxes = lines_sum - commercial_discount

        if commercial_discount.nonzero? && lines_sum.nonzero?
          discount_rate = commercial_discount / lines_sum
        else
          discount_rate = 0.0
        end

        self.vat_amount = 0.0

        lines.each do |line|
          line_total = line.total - (line.total * discount_rate)
          self.vat_amount += (line_total * line.vat_rate / 100.0)
        end

        self.total_including_taxes = total_excluding_taxes + vat_amount
        self.balance               = total_including_taxes - advance
      end

      def pdf
        pdf = ::Dorsale::BillingMachine.invoice_pdf_model.new(self)
        pdf.build
        pdf
      end

      def vat_rate
        if ::Dorsale::BillingMachine.vat_mode == :multiple
          raise "Invoice#vat_rate is not available in multiple vat mode"
        end

        return @vat_rate if @vat_rate

        vat_rates = lines.map(&:vat_rate).uniq

        if vat_rates.length > 1
          raise "Invoice has multiple vat rates"
        end

        vat_rates.first || ::Dorsale::BillingMachine::DEFAULT_VAT_RATE
      end

      def vat_rate=(value)
        @vat_rate = value
      end

      before_validation :apply_vat_rate_to_lines

      def apply_vat_rate_to_lines
        return if ::Dorsale::BillingMachine.vat_mode == :multiple

        lines.each do |line|
          line.vat_rate = vat_rate
        end
      end

      def payment_status
        if paid?
          return :paid
        elsif due_date == nil
          return :on_alert
        elsif Date.today >= due_date + 15
          return :on_alert
        elsif Date.today > due_date
          return :late
        else
          return :pending
        end
      end

      def t(*args)
        return super if args.any?

        if balance && balance < 0
          super(:credit_note)
        else
          self.class.t
        end
      end

      def total_excluding_taxes=(*); super; end
      private :total_excluding_taxes=

      def vat_amount=(*); super; end
      private :vat_amount=

      def total_including_taxes=(*); super; end
      private :total_including_taxes=

      def balance=(*); super; end
      private :balance=

      def self.to_csv(options = { :force_quotes => true, :col_sep => ";" })
        CSV.generate(options) do |csv|
          column_names = [
            "Date",
            "Numéro",
            "Objet",
            "Client",
            "Adresse 1",
            "Adresse 2",
            "Code postal",
            "Ville",
            "Pays",
            "Remise commerciale",
            "Montant HT",
            "Montant TVA",
            "Montant TTC",
            "Acompte",
            "Solde à payer"
          ]

          csv << column_names

          all.each do |invoice|
            csv << [
              invoice.date,
              invoice.tracking_id,
              invoice.label,
              invoice.customer.try(:name),
              invoice.customer.try(:address).try(:street),
              invoice.customer.try(:address).try(:street_bis),
              invoice.customer.try(:address).try(:zip),
              invoice.customer.try(:address).try(:city),
              invoice.customer.try(:address).try(:country),
              french_number(invoice.commercial_discount),
              french_number(invoice.total_excluding_taxes),
              french_number(invoice.vat_amount),
              french_number(invoice.total_including_taxes),
              french_number(invoice.advance),
              french_number(invoice.balance)
            ]
          end
        end
      end

      def self.french_number amount
        extend ActionView::Helpers::NumberHelper
        number_with_precision(amount, :delimiter => '', :separator => ",", :precision => 2)
      end

    end # Invoice
  end # BillingMachine
end # Dorsale
