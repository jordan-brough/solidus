module Spree
  class OrderMutex
    class LockFailed < StandardError
      def initialize(order)
        @order = order
        super("Could not obtain lock on order #{order.id}")
      end
    end

    # 'locker' should be an object that responds to 'lock(order)'. If a lock is
    # obtained then the method should yield, return the yielded value and then
    # release the lock. Otherwise it should raise a
    # Spree::OrderMutex::LockFailed error. Any locks older than
    # Spree::Config[:order_mutex_max_age] should be ignored or automatically
    # removed.
    class_attribute :locker
    self.locker = Spree::OrderMutex::Model

    class << self
      # Obtain a lock on an order.  If the lock is obtained, yield and return
      # the yielded value and then release the lock.  Otherwise raise a
      # LockFailed error. We raise instead of blocking to avoid tying up
      # multiple server processes waiting for the lock. Locks older than
      # Spree::Config[:order_mutex_max_age] are ignored.
      def with_lock!(order)
        raise ArgumentError, "order must be supplied" if order.nil?

        locker.lock(order) do
          begin
            yield
          rescue Spree::OrderMutex::LockFailed => e
            Rails.logger.error(e.inspect)
            raise
          end
        end
      end
    end
  end
end
