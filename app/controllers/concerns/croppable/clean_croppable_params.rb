require "active_support/concern"
require "croppable/param"

ActionController::Parameters::PERMITTED_SCALAR_TYPES << Croppable::Param

module Croppable
  module CleanCroppableParams
    extend ActiveSupport::Concern

    included do
      before_action :setup_croppable_params, only: [:create, :update]
    end

    private

    def setup_croppable_params
      if params[:croppables]
        params[:croppables].each do |(input_name, croppable)|
          params[input_name] ||= {}
          delete = croppable[:delete] == "1"
          params[input_name][croppable[:attr]] = Croppable::Param.new(croppable[:image], croppable[:data], delete: delete)
        end
      end
    end
  end
end