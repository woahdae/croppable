require 'open-uri'
require 'vips'

module Croppable
  class Crop
    def initialize(model, attr_name, uploaded_file: nil)
      @model         = model
      @attr_name     = attr_name
      @uploaded_file = uploaded_file || {}
      @data          = model.send("#{attr_name}_croppable_data")
      @setup         = model.send("#{attr_name}_croppable_setup")
    end

    def perform()
      uploaded_file_or_original do |file|
        vips_img = Vips::Image.new_from_file(file.path)

        height = vips_img.height
        width  = vips_img.width

        x = ((width  - (width  * @data.scale)) / 2 + @data.x) * @setup[:scale]
        y = ((height - (height * @data.scale)) / 2 + @data.y) * @setup[:scale]

        background = @data.background_color.remove("#").scan(/\w{2}/).map {|color| color.to_i(16) }
        background_embed = background.dup
        background_embed << 255 if vips_img.bands == 4

        new_width  = @setup[:width]  * @setup[:scale]
        new_height = @setup[:height] * @setup[:scale]

        vips_img = vips_img.resize(@data.scale * @setup[:scale])
        vips_img = vips_img.embed(x, y, new_width, new_height, background: background_embed)

        path = Tempfile.new('cropped').path + ".jpg"

        vips_img.write_to_file(path, background: background, Q: Croppable.config.image_quality)

        @model.send("#{ @attr_name }_cropped").attach(io: File.open(path), filename: "cropped")
      end
    end

    # When performing an inline job, such as in a test or by choice in an app,
    # we only have the uploaded file; the original will not be written to
    # the storage service until after_commit, and we can't rely on the croppable's
    # after commit coming after Rails' after_commit (in practice it sometimes
    # does, sometimes doesn't, depending on the attachment). Conversely, after
    # the file has been saved to storage and we're in the background job, the
    # tempfile has been cleaned up and we only have the stored file. So, we
    # look for the tempfile, and if not found use the stored file.
    def uploaded_file_or_original(&block)
      if (path = @uploaded_file[:path]) && File.exists?(path)
        block.call(File.open(path))
      else
        @model.send("#{@attr_name}_original").open(&block)
      end
    end
  end
end
