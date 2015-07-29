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
    scope = Spree::CreditCard.where(address_id: nil).includes(payments: :order)

    scope.find_in_batches(batch_size: 500) do |credit_card_batch|
      credit_card_batch.each do |credit_card|
        # remove payments that lack a bill address
        payments = credit_card.payments.select { |p| p.order.bill_address_id }

        payment = payments.sort_by do |p|
          [
            %w(failed invalid).include?(p.state) ? 0 : 1, # prioritize valid payments
            p.created_at, # prioritize more recent payments
          ]
        end.last

        next if payment.nil?

        credit_card.update_column(:address_id, payment.order.bill_address_id)
      end
    end
  end

  def say(message)
    if Rails.env.test?
      Rails.logger.info message
    else
      puts message
    end
  end

end
