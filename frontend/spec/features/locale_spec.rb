require 'spec_helper'

describe "setting locale" do
  before do
    I18n.locale = I18n.default_locale
    I18n.backend.store_translations(:fr, 
     :spree => {
       :cart => "Panier",
       :shopping_cart => "Panier"
    })
    Spree::Frontend::Config[:locale] = "fr"
  end

  after do
    I18n.locale = I18n.default_locale
    Spree::Frontend::Config[:locale] = "en"
  end

  it "should be in french" do
    pending "We don't care about this at the moment"
    visit spree.root_path
    click_link "Panier"
    page.should have_content("Panier")
  end
end
