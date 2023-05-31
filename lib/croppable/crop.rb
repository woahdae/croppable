require 'open-uri'

module Croppable
  class Crop
    # `fit` and `bg` are used for "headless" mode where there is no crop data.
    # `bg_color` is only used in headless mode when `fit` is `:contain` (the
    # default) and fill bars will be added to the image.
    def initialize(model, attr_name, uploaded_file: nil, backend: nil, headless: {})
      @model         = model
      @attr_name     = attr_name
      @uploaded_file = uploaded_file || {}
      @headless_fit  = headless[:fit] || Croppable.config.headless_fit
      @headless_bg   = headless[:bg] || Croppable.config.headless_bg
      @backend       = backend || Croppable.config.crop_backend
      @data          = model.send("#{attr_name}_croppable_data")
      @setup         = model.send("#{attr_name}_croppable_setup")
    end

    def perform
      uploaded_file_or_original { |file| send("process_with_#{@backend}", file) }
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
      cropped_path =
        if (path = @uploaded_file[:path]) && File.exists?(path)
          filename = @uploaded_file[:original_filename]
          block.call(File.open(path))
        end

      cropped_path ||=
        @model.send("#{@attr_name}_original").open do |file|
          filename = @model.send("#{@attr_name}_original").blob&.filename.to_s
          block.call(file)
        end

      @model.send("#{ @attr_name }_cropped").attach(
        io: File.open(cropped_path),
        filename: filename
      )
    end

    def process_with_vips(file)
      img = Vips::Image.new_from_file(file.path)
      @data ||= update_data_via_headless_fit(img)

      x, y = *offsets(width: img.width, height: img.height)

      bg_rgb = background_rgb
      bg_rgb << 255 if img.bands == 4

      img = img.resize(crop_scale)
      img = img.embed(x, y, new_width, new_height, background: bg_rgb)

      path = Tempfile.new('cropped').path + ".jpg"

      # there is a race condition when processing the user-uploaded file,
      # i.e. when not using the stored original, the uploaded file will finish
      # being stored, and deleted, just as we are about to process it.
      # See #uploaded_file_or_original for how this is handled.
      begin
        img.write_to_file(
          path,
          background: background_rgb,
          Q: Croppable.config.image_quality
        )
      rescue Vips::Error
        e.message.match?(/No such file or directory/) ? return : raise
      end

      path
    end

    def process_with_mini_magick(file)
      img = MiniMagick::Image.open(file.path)
      @data ||= update_data_via_headless_fit(img)

      x, y = *offsets(width: img.width, height: img.height)
      x = x.negative? ? "+#{x}" : "-#{x}"
      y = y.negative? ? "+#{y}" : "-#{y}"

      img.format('jpg')
      img.scale("#{crop_scale * 100}%")
      img.combine_options do |opts|
        opts.background(@data.background_color)
        opts.extent("#{new_width}x#{new_height}#{x}#{y}")
      end

      img.path
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

    def update_data_via_headless_fit(img)
      scales = [@setup[:width].to_f / img.width, @setup[:height].to_f / img.height]
      scale =
        case @headless_fit
        when :cover then scales.max
        when :contain then scales.min
        else
          raise "Unknown fit value: #{@headless_fit}"
        end

      data_attr = "#{@attr_name}_croppable_data"
      @model.send("build_#{data_attr}") unless @model.send(data_attr)
      @model.send(data_attr).update(
        scale: scale,
        x: (@setup[:width] - img.width).to_f / 2,
        y: (@setup[:height] - img.height).to_f / 2,
        background_color: @headless_bg
      )
      @model.send(data_attr)
    end
  end
end
