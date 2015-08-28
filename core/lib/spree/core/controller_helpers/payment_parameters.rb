module Spree
  module Core::ControllerHelpers::PaymentParameters

    # Temporarily also providing these as module functions to supported
    # deprecated model-level usage for now.
    module_function

    # This method handles the awkwardness of how the html forms are currently
    # set up for frontend.
    #
    # This method expects a params hash in the format of:
    #
    #  {
    #    payment_source: {
    #      # The keys here are spree_payment_method.id's
    #      '1' => {...source attributes for payment method 1...},
    #      '2' => {...source attributes for payment method 2...},
    #    },
    #    order: {
    #      # Note that only a single entry is expected/handled in this array
    #      payments_attributes: [
    #        {
    #          payment_method_id: '1',
    #        },
    #      ],
    #      ...other params...
    #    },
    #    ...other params...
    #  }
    #
    # And this method modifies the params into the format of:
    #
    #  {
    #    order: {
    #      payments_attributes: [
    #        {
    #          payment_method_id: '1',
    #          source_attributes: {...source attributes for payment method 1...}
    #        },
    #      ],
    #      ...other params...
    #    },
    #    ...other params...
    #  }
    #
    def move_payment_source_into_payments_attributes(params)
      # Step 1: Gather all the information and ensure all the pieces are there.

      return params if params[:payment_source].blank?

      payment_params = params[:order] &&
        params[:order][:payments_attributes] &&
        params[:order][:payments_attributes].first
      return params if payment_params.blank?

      payment_method_id = payment_params[:payment_method_id]
      return params if payment_method_id.blank?

      source_params = params[:payment_source][payment_method_id]
      return params if source_params.blank?

      # Step 2: Perform the modifications.

      payment_params[:source_attributes] = source_params
      params.delete(:payment_source)

      params
    end

    # This method handles the awkwardness of how the html forms are currently
    # set up for frontend.
    #
    # This method expects a params hash in the format of:
    #
    #  {
    #    order: {
    #      existing_card: '123',
    #      ...other params...
    #    },
    #    cvc_confirm: '456', # optional
    #    ...other params...
    #  }
    #
    # And this method modifies the params into the format of:
    #
    #  {
    #    order: {
    #      payments_attributes: [
    #        {
    #          source_attributes: {
    #            existing_card_id: '123',
    #            verification_value: '456',
    #          },
    #        },
    #      ]
    #      ...other params...
    #    },
    #    ...other params...
    #  }
    #
    def move_existing_card_into_payments_attributes(params)
      return params if params[:order].blank?

      card_id = params[:order][:existing_card].presence
      cvc_confirm = params[:cvc_confirm].presence

      return params if card_id.nil?

      params[:order][:payments_attributes] = [
        {
          source_attributes: {
            existing_card_id: card_id,
            verification_value: cvc_confirm,
          }
        },
      ]

      params[:order].delete(:existing_card)
      params.delete(:cvc_confirm)

      params
    end

    def set_payment_parameters_amount(params)
      if params[:payments_attributes]
        params[:payments_attributes].first[:amount] = self.total
      end
    end

  end
end
