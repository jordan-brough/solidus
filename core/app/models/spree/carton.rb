class Spree::Carton < ActiveRecord::Base
  belongs_to :address, class_name: 'Spree::Address', inverse_of: :cartons
  belongs_to :stock_location, class_name: 'Spree::StockLocation', inverse_of: :cartons
  belongs_to :shipping_method, class_name: 'Spree::ShippingMethod', inverse_of: :cartons

  has_many :inventory_units, class_name: "Spree::InventoryUnit", inverse_of: :carton, dependent: :nullify
  has_many :orders, -> { uniq }, through: :inventory_units
  has_many :shipments, -> { uniq }, through: :inventory_units

  validates :address, presence: true
  validates :stock_location, presence: true
  validates :shipping_method, presence: true
  validates :inventory_units, presence: true
  validates :shipped_at, presence: true
  validate :validate_one_store_per_carton

  make_permalink field: :number, length: 11, prefix: 'C'

  scope :trackable, -> { where("tracking IS NOT NULL AND tracking != ''") }
  # sort by most recent shipped_at, falling back to created_at. add "id desc" to make specs that involve this scope more deterministic.
  scope :reverse_chronological, -> { order(shipped_at: :desc, id: :desc) }

  def to_param
    number
  end

  def tracking_url
    @tracking_url ||= shipping_method.build_tracking_url(tracking)
  end

  def order_numbers
    orders.map(&:number)
  end

  def order_emails
    orders.map(&:email).uniq
  end

  def shipment_numbers
    shipments.map(&:number)
  end

  def store
    orders.first.store
  end

  def display_shipped_at
    shipped_at.to_s(:rfc822)
  end

  def manifest
    @manifest ||= Spree::ShippingManifest.new(inventory_units: inventory_units).items
  end

  def manifest_for_order(order)
    Spree::ShippingManifest.new(inventory_units: (inventory_units & order.inventory_units)).items
  end

  def any_exchanges?
    inventory_units.any?(&:original_return_item)
  end

  private

  def validate_one_store_per_carton
    if orders.map(&:store).uniq.size > 1
      errors.add(:base, "Cartons cannot contain items from multiple stores") # TODO: use Spree.t
    end
  end
end
