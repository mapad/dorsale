module Dorsale
  module ExpenseGun
    class Expense < ActiveRecord::Base
      self.table_name = "dorsale_expense_gun_expenses"
      include AASM

      has_many :expense_lines, inverse_of: :expense, dependent: :destroy, class_name: ::Dorsale::ExpenseGun::ExpenseLine

       has_many :attachments,
        :as         => :attachable,
        :dependent  => :destroy,
        :class_name => ::Dorsale::Alexandrie::Attachment


      belongs_to :user, class_name: User
      validates :user, presence: true

      validates :name, presence: true
      validates :date, presence: true

      def initialize(*args)
        super
        self.date = Date.today if self.date.nil?
      end

      # Sum of line amounts
      def total_all_taxes
        expense_lines.map(&:total_all_taxes).sum
      end

      # Sum of line emplee payback
      def total_employee_payback
        expense_lines.map(&:employee_payback).sum
      end

      # Sum of deductible deductible vat
      def total_vat_deductible
        expense_lines.map(&:total_vat_deductible).sum
      end

      def current_state
        aasm.current_state
      end

      aasm(column: :state, whiny_transitions: false) do
        state :new, initial: true
        state :submited
        state :accepted
        state :refused
        state :canceled

        event :submit do
          transitions from: :new, to: :submited
        end

        event :accept do
          transitions from: :submited, to: :accepted
        end

        event :refuse do
          transitions from: :submited, to: :refused
        end

        event :cancel do
          transitions from: [:new, :submited, :accepted], to: :canceled
        end
      end

      def may_edit?
        current_state == :new
      end
    end
  end
end