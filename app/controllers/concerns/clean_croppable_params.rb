require "active_support/concern"
require "croppable/param"

ActionController::Parameters::PERMITTED_SCALAR_TYPES << Croppable::Param

module CleanCroppableParams
  extend ActiveSupport::Concern

  included do
    before_action :setup_croppable_params, only: [:create, :update]
  end

  private

  def setup_croppable_params
    if params[:croppables]
      params[:croppables].each do |(key, croppable)|
        params[croppable[:base]] ||= {}
        params[croppable[:base]][key] = Croppable::Param.new(croppable[:image], croppable[:data])
      end
    end
  end
end
