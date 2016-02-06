module Spree
  class OrderMutex
    class LockFailed < StandardError
      def initialize(order)
        @order = order
        super("Could not obtain lock on order #{order.id}")
      end
    end

    # 'locker' should be an object that responds to 'lock(order)' and acquires
    # an exclusive lock on an Order.
    # If the locker obtains the lock it should yield, return the yielded value
    # and then release the lock.
    # If the locker fails to obtain a lock it should raise a
    # Spree::OrderMutex::LockFailed error.
    # Any locks older than Spree::Config[:order_mutex_max_age] should be ignored
    # and/or automatically removed.
    class_attribute :locker
    self.locker = Spree::OrderMutex::DatabaseLocker

    class << self
      # Obtain a lock on an order.  If the lock is obtained, yield and return
      # the yielded value and then release the lock.
      def with_lock!(order)
        raise ArgumentError, "order must be supplied" if order.nil?

        locker.lock(order) do
          yield
        end
      end
    end
  end
end
