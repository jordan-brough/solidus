class RemoveTaxRateFromShippingRate < ActiveRecord::Migration
  def up
    Spree::ShippingRate.find_each do |shipping_rate|
      tax_rate_id = shipping_rate.tax_rate_id
      if tax_rate_id
        tax_rate = Spree::TaxRate.unscoped.find_by(shipping_rate.tax_rate_id)
        shipping_rate.taxes.create(
          tax_rate: tax_rate,
          amount: tax_rate.compute_amount(shipping_rate)
        )
      end
    end

    remove_column :spree_shipping_rates, :tax_rate_id
  end

  def down
    add_reference :spree_shipping_rates, :tax_rate, index: true, foreign_key: true

    Spree::ShippingRate.find_each do |shipping_rate|
      shipping_taxes = Spree::ShippingRateTax.where(shipping_rate_id: shipping_rate.id)
      # We can only use one tax rate, so let's take the biggest.
      selected_tax = shipping_taxes.sort_by(&:amount).last
      if selected_tax
        shipping_rate.update(tax_rate_id: tax_rate_id)
      end
    end
  end
end
