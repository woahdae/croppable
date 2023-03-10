require "test_helper"

module Croppable
  class CropTest < ActiveJob::TestCase
    setup do
      @file = File.open(file_fixture("moon.jpg"))
      image   = {io: @file, filename: "moon", content_type: "image/jpeg"}
      data    = {x: 20, y: 42, scale: 0.5, background_color: "#BADA55"}
      logo    = Croppable::Param.new(image, data)
      @product = Product.new(name: :moon, logo: logo)
      @product.save
    end

    test "crop image to the specified size" do
      @product.reload

      Croppable::Crop.new(@product, :logo, @file).perform()

      @product.reload

      @product.logo.open do |logo|
        image = Vips::Image.new_from_file(logo.path)

        assert_equal image.width,  200
        assert_equal image.height, 300
      end
    end
  end
end
