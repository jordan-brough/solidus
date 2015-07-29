require 'spec_helper'

describe 'spree:migrations:copy_order_bill_address_to_credit_card' do
  before do
    Rails.application.load_tasks
    task.reenable
  end

  describe 'up' do
    let(:task) do
      Rake::Task['spree:migrations:copy_order_bill_address_to_credit_card:up']
    end

    context 'without any payment' do
      let!(:credit_card) { create(:credit_card) }

      it 'does not update the credit card with an address' do
        expect {
          task.invoke
        }.not_to change { Spree::Address.count }

        expect(credit_card.reload.address_id).to be_nil
      end
    end

    context 'with a completed payment' do
      let!(:credit_card) { create(:credit_card) }

      let!(:payment) do
        create(:credit_card_payment,
          source: credit_card,
          state: 'completed',
          order: create(:order, bill_address: bill_address),
        )
      end

      let(:bill_address) { create(:address, address1: '123 bill address') }

      it 'updates the credit card with the address' do
        expect {
          task.invoke
        }.to change { Spree::Address.count }.by(1)

        address = Spree::Address.last
        expect(credit_card.reload.address_id).to eq(address.id)
        expect(address).to be_same_as(bill_address)
      end
    end

    context 'with a completed payment with an invalid bill address' do
      let!(:credit_card) { create(:credit_card) }

      let!(:payment) do
        create(:credit_card_payment,
          source: credit_card,
          state: 'completed',
          order: create(:order, bill_address: bill_address),
        )
      end

      let(:bill_address) { create(:address, address1: '123 bill address') }

      before do
        bill_address.update_columns(firstname: nil)
      end

      it 'does not update the credit card with an address' do
        expect {
          task.invoke
        }.not_to change { Spree::Address.count }

        expect(credit_card.reload.address_id).to be_nil
      end
    end

    context 'with a failed payment' do
      let!(:credit_card) { create(:credit_card) }

      let!(:payment) do
        create(:credit_card_payment,
          source: credit_card,
          state: 'failed',
          order: create(:order, bill_address: bill_address),
        )
      end

      let(:bill_address) { create(:address, address1: '123 bill address') }

      it 'updates the credit card with the address' do
        expect {
          task.invoke
        }.to change { Spree::Address.count }.by(1)

        address = Spree::Address.last
        expect(credit_card.reload.address_id).to eq(address.id)
        expect(address).to be_same_as(bill_address)
      end
    end

    context 'with multiple credit cards' do
      let!(:credit_card_1) { create(:credit_card) }
      let!(:credit_card_2) { create(:credit_card) }

      let!(:payment_1) do
        create(:credit_card_payment,
          source: credit_card_1,
          state: 'completed',
          order: create(:order, bill_address: bill_address_1),
        )
      end
      let!(:payment_2) do
        create(:credit_card_payment,
          source: credit_card_2,
          state: 'completed',
          order: create(:order, bill_address: bill_address_2),
        )
      end

      let(:bill_address_1) { create(:address, address1: '123 bill address') }
      let(:bill_address_2) { create(:address, address1: '123 bill address') }

      it 'updates each credit card with the correct address' do
        expect {
          task.invoke
        }.to change { Spree::Address.count }.by(2)

        address_1, address_2 = Spree::Address.order(id: :desc).limit(2).to_a.reverse

        expect(address_1.id).to eq credit_card_1.reload.address_id
        expect(address_2.id).to eq credit_card_2.reload.address_id

        expect(address_1).to be_same_as(bill_address_1)
        expect(address_2).to be_same_as(bill_address_2)
      end
    end

    context 'with a two completed payments' do
      let!(:credit_card) { create(:credit_card) }

      let!(:payment_1) do
        create(:credit_card_payment,
          source: credit_card,
          state: 'completed',
          created_at: 1.day.ago,
          order: create(:order, bill_address: bill_address_1)
        )
      end
      let!(:payment_2) do
        create(:credit_card_payment,
          source: credit_card,
          state: 'completed',
          created_at: Time.now, # more recent than the completed one
          order: create(:order, bill_address: bill_address_2)
        )
      end

      let(:bill_address_1) { create(:address, address1: '123 address 1') }
      let(:bill_address_2) { create(:address, address1: '456 address 2') }

      it 'updates the credit card with the more recent address' do
        expect {
          task.invoke
        }.to change { Spree::Address.count }.by(1)

        address = Spree::Address.last
        expect(address.id).to eq credit_card.reload.address_id
        expect(address).to be_same_as(bill_address_2)
      end
    end

    context 'with a completed payment and a more recent failed payment' do
      let!(:credit_card) { create(:credit_card) }

      let!(:completed_payment) do
        create(:credit_card_payment,
          source: credit_card,
          state: 'completed',
          created_at: 1.day.ago,
          order: create(:order, bill_address: completed_bill_address)
        )
      end
      let!(:failed_payment) do
        create(:credit_card_payment,
          source: credit_card,
          state: 'failed',
          created_at: Time.now, # more recent than the completed one
          order: create(:order, bill_address: failed_bill_address)
        )
      end

      let(:completed_bill_address) { create(:address, address1: '123 completed address') }
      let(:failed_bill_address) { create(:address, address1: '456 failed address') }

      it 'updates the credit card with the less recent completed address' do
        expect {
          task.invoke
        }.to change { Spree::Address.count }.by(1)

        address = Spree::Address.last
        expect(address.id).to eq credit_card.reload.address_id
        expect(address).to be_same_as(completed_bill_address)
      end
    end

    context 'with a completed payment and a more recent checkout payment' do
      let!(:credit_card) { create(:credit_card) }

      let!(:completed_payment) do
        create(:credit_card_payment,
          source: credit_card,
          state: 'completed',
          created_at: 1.day.ago,
          order: create(:order, bill_address: completed_bill_address)
        )
      end
      let!(:checkout_payment) do
        create(:credit_card_payment,
          source: credit_card,
          state: 'checkout',
          created_at: Time.now, # more recent than the completed one
          order: create(:order, bill_address: checkout_bill_address)
        )
      end

      let(:completed_bill_address) { create(:address, address1: '123 completed address') }
      let(:checkout_bill_address) { create(:address, address1: '456 checkout address') }

      it 'updates the credit card with the less recent completed address' do
        expect {
          task.invoke
        }.to change { Spree::Address.count }.by(1)

        address = Spree::Address.last
        expect(address.id).to eq credit_card.reload.address_id
        expect(address).to be_same_as(completed_bill_address)
      end
    end

  end
end
