namespace 'spree:migrations:copy_order_bill_address_to_credit_card' do
  # This copies the billing address from the order associated with a
  # credit card's most recent payment to the credit card.

  # Used in the migration CopyOrderBillAddressToCreditCard and made available as a
  # rake task to allow running it a second time after deploying the new code, in
  # case some order->credit card data was missed between the time that the
  # migration was run and the application servers were restarted with the new
  # code.

  # This task should be safe to run multiple times.

  task up: :environment do
    say "Copying order bill addresses to credit cards"

    copy_addresses
  end

  task down: :environment do
    Spree::CreditCard.update_all(address_id: nil)
  end

  def copy_addresses
    scope = Spree::CreditCard.where(address_id: nil).includes(payments: {order: :bill_address})

    start = Time.now
    batch_start = start

    batch_size = 500
    batch_iteration = 0

    log_filename = Rails.root.join(
      "log/copy_order_bill_address_to_credit_card.#{Time.now.to_i}.log"
    )
    log = File.open(log_filename, 'w')

    scope.find_in_batches(batch_size: batch_size) do |credit_card_batch|
      batch_iteration += 1

      credit_card_batch.each do |credit_card|
        # remove payments that lack a bill address
        payments = credit_card.payments.select { |p| p.order.bill_address }

        payments.sort_by! do |p|
          [
            payment_state_sort_number(p.state), # prioritize more-valid payments over less-valid payments
            p.created_at, # prioritize more recent payments
          ]
        end

        # only call #invalid? as many times as we have to since it requires db lookups
        while payments.any? && payments.last.order.bill_address.invalid?
          payments.pop
        end

        payment = payments.last

        next if payment.nil?

        address = payment.order.bill_address.dup
        address.save!

        credit_card.update_columns(address_id: address.id)

        if !Rails.env.test?
          log.puts "credit_card_id=#{credit_card.id} address_id=#{address.id} bill_address_id=#{payment.order.bill_address_id}"
        end
      end

      say "Finished batch of #{batch_size} in #{(Time.now - batch_start).round(1)}s"
      say "Finished #{batch_size*batch_iteration} records total in #{(Time.now - start).round(1)}s"

      batch_start = Time.now
    end
  end

  def payment_state_sort_number(state)
    payment_state_sort_hash[state] || -1
  end

  def payment_state_sort_hash
    @payment_state_sort_hash ||= {
      "completed" => 7,
      "pending" => 6,
      "processing" => 5,
      "checkout" => 4,
      "invalid" => 3,
      "void" => 2,
      "failed" => 1,
    }
  end

  def say(message)
    if Rails.env.test?
      Rails.logger.info message
    else
      puts message
    end
  end

end
