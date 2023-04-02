require 'open-uri'

module Croppable
  class Crop
    def backend
      @backend || Croppable.config.crop_backend
    end

    def initialize(model, attr_name, uploaded_file: nil, backend: nil)
      @model         = model
      @attr_name     = attr_name
      @uploaded_file = uploaded_file || {}
      @backend       = backend
      @data          = model.send("#{attr_name}_croppable_data")
      @setup         = model.send("#{attr_name}_croppable_setup")
    end

    def perform()
      uploaded_file_or_original { |file| send("process_with_#{backend}", file) }
    end

    private

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

    def process_with_vips(file)
      img = Vips::Image.new_from_file(file.path)

      x, y = *offsets(width: img.width, height: img.height)

      bg_rgb = background_rgb
      bg_rgb << 255 if img.bands == 4

      img = img.resize(crop_scale)
      img = img.embed(x, y, new_width, new_height, background: bg_rgb)

      path = Tempfile.new('cropped').path + ".jpg"

      img.write_to_file(path, background: background_rgb, Q: Croppable.config.image_quality)

      @model.send("#{ @attr_name }_cropped").attach(io: File.open(path), filename: "cropped")
    end

    def process_with_mini_magick(file)
      img = MiniMagick::Image.open(file.path)

      x, y = *offsets(width: img.width, height: img.height)
      x = x.negative? ? "+#{x}" : "-#{x}"
      y = y.negative? ? "+#{y}" : "-#{y}"

      img.format('jpg')
      img.scale("#{crop_scale * 100}%")
      img.combine_options do |opts|
        opts.background(@data.background_color)
        opts.extent("#{new_width}x#{new_height}#{x}#{y}")
      end

      @model.send("#{ @attr_name }_cropped").attach(io: File.open(img.path), filename: "cropped")
    end

    def offsets(width:, height:)
      [ offset_for(:x, width), offset_for(:y, height) ]
    end

    def offset_for(axis, length)
      ((length  - (length  * @data.scale)) / 2 + @data.send(axis)) * @setup[:scale]
    end

    def new_width
      @setup[:width] * @setup[:scale]
    end

    def new_height
      @setup[:height] * @setup[:scale]
    end

    def crop_scale
      @data.scale * @setup[:scale]
    end

    def background_rgb
      @data.background_color
        .remove("#")
        .scan(/\w{2}/)
        .map {|color| color.to_i(16) }
    end
  end
end
