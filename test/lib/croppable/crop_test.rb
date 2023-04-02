require "test_helper"

module Croppable
  class CropTest < ActiveJob::TestCase
    setup do
      @file = File.open(file_fixture("moon.jpg"))
      image   = {io: @file, filename: "moon", content_type: "image/jpeg"}
      data    = {x: 20, y: 42, scale: 0.5, background_color: "#BADA55"}
      logo    = { image: image, data: data }
      @product = Product.new(name: :moon, logo: logo)
      @product.save
    end

    test "crop image to the specified size with vips" do
      @product.reload

      Croppable::Crop.new(@product, :logo, backend: :vips).perform()

      @product.reload

      @product.logo.open do |logo|
        image = Vips::Image.new_from_file(logo.path)

        assert_equal 200, image.width
        assert_equal 300, image.height
      end
    end

    test "crop image to the specified size with mini_magick" do
      require 'mini_magick'
      @product.reload

      Croppable::Crop.new(@product, :logo, backend: :mini_magick).perform()

      @product.reload

      @product.logo.open do |logo|
        image = MiniMagick::Image.new(logo.path)

        assert_equal 200, image.width
        assert_equal 300, image.height
      end
    end
  end
end
