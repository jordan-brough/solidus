gem 'redlock', '~> 0.1'
require 'redlock'

module Spree
  class OrderMutex
    class RedisLocker < Spree::Base
      # Uses Redlock.  See:
      #   - http://redis.io/topics/distlock
      #   - https://github.com/antirez/redlock-rb
      #   - https://github.com/leandromoreira/redlock-rb

      # Set these in an initializer
      class_attribute :redis_urls
      class_attribute :redis_timeout # optional

      class << self
        def lock(order)
          client.lock!('asdf') { }
          redis_key = order.id
          expire_ms = Spree::Config[:order_mutex_max_age] * 1000

          begin
            client.lock!(redis_key, expire_ms) do
              yield
            end
          rescue Redlock::LockError
            raise Spree::OrderMutex::LockFailed.new(order)
          end
        end

        # private

        def client
          @client ||= begin
            raise 'no redis urls' if redis_urls.blank?
            Redlock::Client.new(
              redis_urls,
              retry_count: 1,
              redis_timeout: redis_timeout,
            )
          end
        end
      end
    end
  end
end
