module Spree
  class OrderMutex < Spree::Base
    # OrderMutex needs a separate database connection. This is because
    # OrderMutex is designed to fail immediately when it cannot obtain a lock on
    # the order, and without a separate connection it could sometimes block.
    # Example scenario:
    #
    # 1) Server A begins processing a task that effectively looks like this:
    #
    #   SomeModel.transaction do
    #     Spree::OrderMutex.with_lock!(some_order) do
    #       ...code that takes a non-trivial amount of time...
    #     end
    #   end
    #
    # 2) Server B tries to obtain a mutex "some_order" while Server A is
    # processing the "non-trivial" code.

    # In that case Server B will end up blocking at the DB level until Server A
    # finishes its "non-trivial" code. This is because the OrderMutex db
    # insertion that `with_lock!` triggers is wrapped inside the outer
    # `SomeModel.transaction`. On the other hand, if OrderMutex uses a separate
    # database connection then its insertion will not be inside the outer
    # transaction and will be committed immediately and OrderMutex will only
    # block for as long as it takes to insert a single row into the table.
    #
    # Some downsides to using a separate connection:
    #   - Doubles the number of connections required to your database.
    #   - When running specs the order_mutexes table is not automatically
    #     cleaned up by the deafult transaction that wraps all spec DB
    #     modifications. However, the "ensure" clause in this code should take
    #     care of cleanup in almost all cases.
    if connection.adapter_name !~ /sqlite/i
      establish_connection(connection_config)
    end

    class LockFailed < StandardError; end

    belongs_to :order, class_name: "Spree::Order"

    scope :expired, -> { where(arel_table[:created_at].lteq(Spree::Config[:order_mutex_max_age].seconds.ago)) }

    class << self
      # Obtain a lock on an order, execute the supplied block and then release the lock.
      # Raise a LockFailed exception immediately if we cannot obtain the lock.
      # We raise instead of blocking to avoid tying up multiple server processes waiting for the lock.
      def with_lock!(order)
        raise ArgumentError, "order must be supplied" if order.nil?

        # limit the maximum lock time just in case a lock is somehow left in place accidentally
        expired.where(order: order).delete_all

        begin
          order_mutex = create!(order: order)
        rescue ActiveRecord::RecordNotUnique
          error = LockFailed.new("Could not obtain lock on order #{order.id}")
          logger.error error.inspect
          raise error
        end

        yield

      ensure
        order_mutex.destroy if order_mutex
      end
    end
  end
end
