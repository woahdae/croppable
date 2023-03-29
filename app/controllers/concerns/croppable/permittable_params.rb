module Croppable
  module PermittableParams
    # Keys that need to be permitted when using strong parameters.
    #
    # Usage:
    #
    # ```ruby
    # def product_params
    #   params.require(:product).permit(logo: croppable_params)
    # end
    # ```
    def croppable_params
      [:image, :delete, { data: %i[x y scale background_color] }]
    end
  end
end
