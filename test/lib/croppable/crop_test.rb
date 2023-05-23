require "test_helper"

module Croppable
  class CropTest < ActiveJob::TestCase
    setup do
      @file = File.open(file_fixture("moon.jpg"))
      @image   = { io: @file, filename: "moon" }
      @data    = { x: 20, y: 42, scale: 0.5, background_color: "#BADA55" }
      @logo    = { image: @image, data: @data }
    end

    test "crop image to the specified size with vips" do
      @product = Product.create(name: :moon, logo: @logo)

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
      @product = Product.create(name: :moon, logo: @logo)

      Croppable::Crop.new(@product, :logo).perform

      @product.reload

      @product.logo.open do |logo|
        image = MiniMagick::Image.new(logo.path)

        assert_equal 200, image.width
        assert_equal 300, image.height
      end
    end

    test "using :contain headless fit, can crop without JS crop data" do
      logo = { image: @image, data: nil }
      @product = Product.create(name: :moon, logo: logo)

      Croppable::Crop.new(@product, :logo, backend: :vips, headless: { fit: :contain }).perform

      assert_equal -12, @product.logo_croppable_data.x
      assert_equal 37, @product.logo_croppable_data.y
      assert_equal 0.88889, @product.logo_croppable_data.scale.round(5)
      assert_equal '#ffffff', @product.logo_croppable_data.background_color
    end

    test "using :cover fit, can crop without JS crop data (headless)" do
      logo = { image: @image, data: nil }
      @product = Product.create(name: :moon, logo: logo)

      Croppable::Crop.new(@product, :logo, backend: :vips, headless: { fit: :cover }).perform

      assert_equal -12, @product.logo_croppable_data.x
      assert_equal 37, @product.logo_croppable_data.y
      assert_equal 1.33333, @product.logo_croppable_data.scale.round(5)
      assert_equal '#ffffff', @product.logo_croppable_data.background_color
    end
  end
end
