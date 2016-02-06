module Spree
  class OrderMutex
    class DatabaseLocker < Spree::Base
      self.table_name = 'spree_order_mutexes'

      belongs_to :order, class_name: "Spree::Order"

      scope :expired, -> do
        oldest_allowed_time = Spree::Config[:order_mutex_max_age].seconds.ago
        where(arel_table[:created_at].lteq(oldest_allowed_time))
      end

      def self.lock(order)
        # limit the maximum lock time just in case a lock is somehow left in
        # place accidentally
        expired.where(order: order).delete_all

        begin
          order_mutex = create!(order: order)
        rescue ActiveRecord::RecordNotUnique
          raise Spree::OrderMutex::LockFailed.new(order)
        end

        yield
      ensure
        order_mutex.destroy if order_mutex
      end

      # OrderMutex needs a separate database connection. This is because
      # OrderMutex is designed to fail immediately when it cannot obtain a lock
      # on the order, and without a separate connection it could sometimes
      # block.
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

      # In that case Server B will end up blocking at the DB level until Server
      # A finishes its "non-trivial" code. This is because the OrderMutex db
      # insertion that `with_lock!` triggers is wrapped inside the outer
      # `SomeModel.transaction`. On the other hand, if OrderMutex uses a
      # separate database connection then its insertion will not be inside the
      # outer transaction and will be committed immediately and OrderMutex will
      # only block for as long as it takes to insert a single row into the
      # table.
      #
      # Some downsides to using a separate connection:
      #   - Doubles the number of connections required to your database.
      #   - When running specs the order_mutexes table is not automatically
      #     cleaned up by the deafult transaction that wraps all spec DB
      #     modifications. However, the "ensure" clause in `lock` should take
      #     care of cleanup in almost all cases.
      if connection.adapter_name !~ /sqlite/i
        establish_connection(connection_config)
      end
    end
  end
end
