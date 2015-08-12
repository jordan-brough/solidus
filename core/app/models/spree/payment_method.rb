module Spree
  class PaymentMethod < Spree::Base
    acts_as_paranoid
    DISPLAY = [:both, :front_end, :back_end]
    default_scope -> { where(deleted_at: nil) }

    validates :name, presence: true

    has_many :payments, class_name: "Spree::Payment", inverse_of: :payment_method
    has_many :credit_cards, class_name: "Spree::CreditCard"

    # Extension point to add extra conditions to {available}. For a payment method
    # to be deemed available, both the standard conditions in {available} and the
    # result of calling this must be true. Is passed a {PaymentMethod} and the
    # options hash passed to {#available}.
    #
    # @api public
    class_attribute :available_extra_conditions
    self.available_extra_conditions = -> (payment_method, options) { true }

    include Spree::Preferences::StaticallyConfigurable

    def self.providers
      Rails.application.config.spree.payment_methods
    end

    def provider_class
      raise ::NotImplementedError, "You must implement provider_class method for #{self.class}."
    end

    # The class that will process payments for this payment type, used for @payment.source
    # e.g. CreditCard in the case of a the Gateway payment type
    # nil means the payment method doesn't require a source e.g. check
    def payment_source_class
      raise ::NotImplementedError, "You must implement payment_source_class method for #{self.class}."
    end

    def self.available(options = {})
      unless options.is_a?(Hash)
        ActiveSupport::Deprecation.warn("This method now takes an options hash as an argument (e.g. { display_on: 'both' }")
        options = { display_on: options }
      end
      options[:display_on] ||= 'both'
      all.select do |p|
        p.active &&
        (p.display_on == options[:display_on].to_s || p.display_on.blank?) &&
        self.available_extra_conditions.call(p, options)
      end
    end

    def self.active?
      where(type: self.to_s, active: true).count > 0
    end

    def method_type
      type.demodulize.downcase
    end

    def self.find_with_destroyed *args
      unscoped { find(*args) }
    end

    def payment_profiles_supported?
      false
    end

    def source_required?
      true
    end

    # Custom gateways should redefine this method. See Gateway implementation
    # as an example
    def reusable_sources(order)
      []
    end

    def auto_capture?
      self.auto_capture.nil? ? Spree::Config[:auto_capture] : self.auto_capture
    end

    def supports?(source)
      true
    end

    def cancel(response)
      raise ::NotImplementedError, 'You must implement cancel method for this payment method.'
    end

    def store_credit?
      is_a? Spree::PaymentMethod::StoreCredit
    end
  end
end
