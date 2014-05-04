require 'spec_helper'

describe Spree::Calculator::TieredPercent do
  let(:calculator) { Spree::Calculator::TieredPercent.new }

  describe "#valid?" do
    subject { calculator.valid? }
    context "when base percent is less than zero" do
      before { calculator.preferred_base_percent = -1 }
      it { should be false }
    end
    context "when base percent is greater than 100" do
      before { calculator.preferred_base_percent = 110 }
      it { should be false }
    end
    context "when tiers is a hash" do
      context "and one of the keys is not a positive number" do
        before { calculator.preferred_tiers = { "nope" => 20 } }
        it { should be false }
      end
      context "and one of the values is not a percent" do
        before { calculator.preferred_tiers = { 10 => 110 } }
        it { should be false }
      end
    end
  end

  describe "#compute" do
    let(:line_item) { mock_model Spree::LineItem, amount: amount }
    before do
      calculator.preferred_base_percent = 10
      calculator.preferred_tiers = {
        100 => 15,
        200 => 20
      }
    end
    subject { calculator.compute(line_item) }
    context "when amount falls within the first tier" do
      let(:amount) { 50 }
      it { should eq 5 }
    end
    context "when amount falls within the second tier" do
      let(:amount) { 150 }
      it { should eq 22.5 }
    end
  end
end