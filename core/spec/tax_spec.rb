require 'spec_helper'

describe 'caching for taxes would get broken in the middle of applying a promo' do
  specify do
    #
    # Setup an order with two line items, each $10, and $0 shipping.
    #
    tax_category = create(:tax_category)

    variant1 = create(:variant, tax_category: tax_category, price: 10.00)
    variant2 = create(:variant, tax_category: tax_category, price: 10.00)

    order = create(:order)

    ship_address_zone = create(:zone, countries: [order.ship_address.country])

    create(:tax_rate, amount: 0.1, zone: ship_address_zone, tax_category: tax_category)

    order.contents.add(variant1)
    order.contents.add(variant2)

    shipping_method = create(:shipping_method, cost: 0, zones: [ship_address_zone])

    order.next! until order.payment?

    #
    # Create a promo to verify the problem
    #
    promo = create(:promotion, :with_line_item_adjustment, adjustment_rate: 2.00)

    tax_calls_count = 0

    allow_any_instance_of(Spree::TaxRate).to receive(:compute_amount).and_wrap_original { |method, *args|
      case tax_calls_count
      when 0
        #
        # THE PROBLEM: TaxRate#compute_amount gets called twice, and the first
        # time we aren't ready to calculate tax on the entire order because not
        # all the line items have been updated with the promotion yet.
        # i.e. The fact that this next expectation *passes* is the problem.
        #
        expect(order.line_items.map(&:promo_total)).to match_array([-2,  0])
      when 1
        expect(order.line_items.map(&:promo_total)).to match_array([-2, -2])
      else
        raise "unexpected compute_amount invocation"
      end

      tax_calls_count += 1

      method.call(*args)
    }

    promo.activate(order: order)

    expect(tax_calls_count).to eq(2)
  end
end
