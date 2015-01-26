module Spree
  module Admin
    module Orders
      class CustomerDetailsController < Spree::Admin::BaseController
        before_action :load_order

        def show
          edit
          render action: :edit
        end

        def edit
          country_id = Address.default.country.id
          @order.build_bill_address(country_id: country_id) if @order.bill_address.nil?
          @order.build_ship_address(country_id: country_id) if @order.ship_address.nil?

          @order.bill_address.country_id = country_id if @order.bill_address.country.nil?
          @order.ship_address.country_id = country_id if @order.ship_address.country.nil?
        end

        def update
          if @order.contents.update_cart(order_params)
            if params[:guest_checkout] == "false"
              requested_user = Spree.user_class.find(params[:user_id])
              @order.contents.associate_user(requested_user, @order.email.blank?)
            end
            @order.next
            @order.refresh_shipment_rates
            flash[:success] = Spree.t('customer_details_updated')
            redirect_to edit_admin_order_url(@order)
          else
            render action: :edit
          end

        end

        private
          def order_params
            params.require(:order).permit(
              :email,
              :use_billing,
              bill_address_attributes: permitted_address_attributes,
              ship_address_attributes: permitted_address_attributes
            )
          end

          def load_order
            @order = Order.includes(:adjustments).find_by_number!(params[:order_id])
          end

          def model_class
            Spree::Order
          end

      end
    end
  end
end
