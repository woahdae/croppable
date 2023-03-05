module Croppable
  module TagHelper
    def croppable_image_tag(name, method, value, object, options = {})
      width  = options["width"]  || object.send("#{ method }_croppable_setup")[:width]
      height = options["height"] || object.send("#{ method }_croppable_setup")[:height]

      render "croppable/tag", width: width, height: height, method: method, name: name
    end
  end
end

module ActionView::Helpers
  class Tags::CroppableImage < Tags::Base
    delegate :dom_id, to: ActionView::RecordIdentifier

    def render
      options = @options.stringify_keys

      add_default_name_and_id(options)

      options["input"] ||= dom_id(object, [options["id"], :croppable].compact.join("_")) if object

      html_tag = @template_object.croppable_image_tag(@object_name, @method_name, options.fetch("value") { value }, object, options.except("value"))

      error_wrapping(html_tag)
    end
  end

  module FormHelper
    def croppable_image(object_name, method, options = {})
      Tags::CroppableImage.new(object_name, method, self, options).render
    end
  end

  class FormBuilder
    def croppable_image(method, options = {})
      self.multipart = true

      @template.croppable_image(@object_name, method, objectify_options(options))
    end
  end
end
