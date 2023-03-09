module Croppable
  module Model
    extend ActiveSupport::Concern

    # High-resolution displays, which are a large part of the market, need twice
    # the pixels to look professional.
    DEFAULT_RESOLUTION = 2

    class_methods do
      def has_croppable(name, width:, height:, resolution: DEFAULT_RESOLUTION)
        has_one_attached :"#{ name }_cropped"
        has_one_attached :"#{ name }_original"

        has_one :"#{ name }_croppable_data", -> { where(name: name) },
          as: :croppable, inverse_of: :croppable, dependent: :destroy, class_name: "Croppable::Datum"

        after_commit if: -> { to_crop_croppable[name] } do
          Croppable::CropImageJob.perform_later(self, name)
        end

        generated_association_methods.class_eval <<-CODE, __FILE__, __LINE__ + 1
          def #{ name }_croppable_setup
            {width: #{ width }, height: #{ height }, resolution: #{ resolution }}
          end

          def to_crop_croppable
            @to_crop_croppable ||= Hash.new
          end

          def #{ name }
            self.#{ name }_cropped
          end

          def #{ name }=(croppable_param)
            if croppable_param.delete
              self.#{ name }_original       = nil
              self.#{ name }_cropped        = nil
              self.#{ name }_croppable_data = nil
            else
              self.#{ name }_original = croppable_param.image if croppable_param.image

              if self.#{ name }_original.present?
                if self.#{ name }_croppable_data
                  self.#{ name }_croppable_data.update(croppable_param.data)
                else
                  self.#{ name }_croppable_data = Croppable::Datum.new(croppable_param.data.merge(name: "#{ name }"))
                end

                to_crop_croppable[:#{ name }] = self.#{ name }_croppable_data.updated_at_previously_changed? || self.#{ name }_croppable_data.new_record?
              end
            end
          end
        CODE
      end
    end
  end
end
