require 'open-uri'
require 'vips'

module Croppable
  class Crop
    def initialize(model, attr_name)
      @model     = model
      @attr_name = attr_name
      @data      = model.send("#{attr_name}_croppable_data")
      @setup     = model.send("#{attr_name}_croppable_setup")
    end

    def perform()
      @model.send("#{@attr_name}_original").open do |file|
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

        vips_img.write_to_file(path, background: background, Q: 100)

        @model.send("#{ @attr_name }_cropped").attach(io: File.open(path), filename: "cropped")
      end
    end
  end
end
