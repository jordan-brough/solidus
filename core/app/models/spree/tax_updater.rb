class Spree::TaxUpdater
  def initialize(order)
    self.order = order
  end

  def update
    [*order.line_items, *order.shipments].each do |item|
      update_item_tax(item)
    end
  end

  private

  attr_accessor :order

  def update_item_tax(item)
    tax_adjustments = item.adjustments.select(&:tax?)

    item.included_tax_total = tax_adjustments.select(&:included?).
      map(&:update!).
      compact.
      sum

    item.additional_tax_total = tax_adjustments.reject(&:included?).
      map(&:update!).
      compact.
      sum
  end
end
