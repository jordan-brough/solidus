require 'spec_helper'

describe Spree::PaymentMethod, :type => :model do
  describe "#available" do
    before do
      [nil, 'both', 'front_end', 'back_end'].each do |display_on|
        Spree::Gateway::Test.create(
          :name => 'Display Both',
          :display_on => display_on,
          :active => true,
          :description => 'foofah'
        )
      end
    end

    it "should have 4 total methods" do
      expect(Spree::PaymentMethod.all.size).to eq(4)
    end

    it "should return all methods available to front-end/back-end when no parameter is passed" do
      expect(Spree::PaymentMethod.available.size).to eq(2)
    end

    it "should return all methods available to front-end/back-end when display_on = :both" do
      expect(Spree::PaymentMethod.available(display_on: :both).size).to eq(2)
    end

    it "should return all methods available to front-end when display_on = :front_end" do
      expect(Spree::PaymentMethod.available(display_on: :front_end).size).to eq(2)
    end

    it "should return all methods available to back-end when display_on = :back_end" do
      expect(Spree::PaymentMethod.available(display_on: :back_end).size).to eq(2)
    end

    context "respects extra conditions" do
      before(:each) do
        allow(Spree::PaymentMethod).to receive(:available_extra_conditions).and_return(-> (payment_method, options) { false })
      end

      it "returns no available methods" do
        expect(Spree::PaymentMethod.available(display_on: :back_end).size).to eq(0)
      end
    end
  end

  describe '#auto_capture?' do
    class TestGateway < Spree::Gateway
      def provider_class
        Provider
      end
    end

    let(:gateway) { TestGateway.new }

    subject { gateway.auto_capture? }

    context 'when auto_capture is nil' do
      before(:each) do
        expect(Spree::Config).to receive('[]').with(:auto_capture).and_return(auto_capture)
      end

      context 'and when Spree::Config[:auto_capture] is false' do
        let(:auto_capture) { false }

        it 'should be false' do
          expect(gateway.auto_capture).to be_nil
          expect(subject).to be false
        end
      end

      context 'and when Spree::Config[:auto_capture] is true' do
        let(:auto_capture) { true }

        it 'should be true' do
          expect(gateway.auto_capture).to be_nil
          expect(subject).to be true
        end
      end
    end

    context 'when auto_capture is not nil' do
      before(:each) do
        gateway.auto_capture = auto_capture
      end

      context 'and is true' do
        let(:auto_capture) { true }

        it 'should be true' do
          expect(subject).to be true
        end
      end

      context 'and is false' do
        let(:auto_capture) { false }

        it 'should be true' do
          expect(subject).to be false
        end
      end
    end
  end

end
