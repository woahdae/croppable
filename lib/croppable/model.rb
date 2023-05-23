module Croppable
  module Model
    extend ActiveSupport::Concern

    class_methods do
      # `headless` is only used when setting images without the browser, in
      # which case it can be:
      #
      # * `{ fit: :contain, bg: '#ffffff' }` (default): padded with bars on the
      #   provided images' short dimension unless provided image matches
      #   defined dimensions exactly. Bars are padded with `:bg`, which must be
      #   a hex code. Defaults to `Croppable.config.headless_bg`, which itself
      #   defaults to `#ffffff`.
      # * `{ fit: :cover }` - provided images' long dimension is cropped, so
      #   that the entire image space is filled without needing to pad.
      #
      # Default `fit` can be set via `Croppable.config.headless_fit
      def has_croppable(name, width:, height:, scale: nil, headless: {}, &block)
        scale ||= Croppable.config.default_scale

        has_one_attached :"#{ name }_cropped", &block
        has_one_attached :"#{ name }_original"

        has_one :"#{ name }_croppable_data", -> { where(name: name) },
          as: :croppable, inverse_of: :croppable, dependent: :destroy, class_name: "Croppable::Datum"

        after_save_commit if: -> { to_crop_croppable[name] } do
          Croppable::CropImageJob.perform_later(
            self, name,
            uploaded_file: to_crop_croppable[name],
            headless: headless
          )
        end

        generated_association_methods.class_eval <<-CODE, __FILE__, __LINE__ + 1
          def #{ name }_croppable_setup
            {width: #{ width }, height: #{ height }, scale: #{ scale }}
          end

          def to_crop_croppable
            @to_crop_croppable ||= Hash.new
          end

          def #{ name }
            self.#{ name }_cropped
          end

          def #{ name }=(croppable_param)
            if croppable_param.nil? || croppable_param[:delete] == '1'
              self.#{ name }_original       = nil
              self.#{ name }_cropped        = nil
              self.#{ name }_croppable_data = nil
            else
              uploaded_file = croppable_param[:image]
              # For headless, we can mirror the `has_one_attached` API
              uploaded_file ||= croppable_param if croppable_param[:io].present?
              self.#{ name }_original = uploaded_file if uploaded_file

              if self.#{ name }_original.present?
                if (data = croppable_param[:data])
                  if #{ name }_croppable_data
                    #{ name }_croppable_data.update(data)
                  else
                    build_#{ name }_croppable_data(data.merge(name: "#{ name }"))
                  end
                end

                if self.#{ name }_croppable_data&.updated_at_previously_changed? ||
                  self.#{ name }_croppable_data&.new_record? ||
                  croppable_param[:data].blank?
                  if uploaded_file.respond_to?(:tempfile)
                    path = uploaded_file.tempfile.path
                    filename = uploaded_file.original_filename
                    content_type = uploaded_file.content_type
                  elsif uploaded_file&.[](:io)
                    path = uploaded_file[:io].path
                    filename = uploaded_file[:filename]
                    content_type = uploaded_file[:content_type]
                  end

                  to_crop_croppable[:#{ name }] = {
                    path: path,
                    original_filename: filename,
                    content_type: content_type
                  }
                end
              end
            end
          end
        CODE
      end
    end
  end
end
