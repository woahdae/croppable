module Croppable
  module Model
    extend ActiveSupport::Concern

    class_methods do
      def has_croppable(name, width:, height:)
        has_one_attached :"#{ name }_cropped"
        has_one_attached :"#{ name }_original"

        has_one :"#{ name }_croppable_data", -> { where(name: name) },
          as: :croppable, inverse_of: :croppable, dependent: :destroy, class_name: "Croppable::Datum"

        after_commit if: -> { @to_crop } do
          crop_image(name)
        end

        after_initialize do
          unless self.send(:"#{ name }_croppable_data")
            self.send(:"#{ name }_croppable_data=", Croppable::Datum.new(name: "#{ name }"))
          end
        end

        generated_association_methods.class_eval <<-CODE, __FILE__, __LINE__ + 1
          def #{ name }_croppable_setup
            {width: #{ width }, height: #{ height }}
          end

          def #{ name }
            self.#{ name }_cropped
          end

          def #{ name }=(croppable_param)
            self.#{ name }_original = croppable_param.image if croppable_param.image
            self.#{ name }_croppable_data ||= Croppable::Datum.new(name: "#{ name }")
            self.#{ name }_croppable_data.update(croppable_param.data)
            @to_crop = true
          end
        CODE
      end
    end

    private

    def crop_image(name)
      Croppable::CropImageJob.perform_later(self, name)
    end
  end
end
