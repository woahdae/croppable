require "test_helper"

class HasCroppableTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @product = Product.new(name: :cat)
  end

  test "has a logo relationships" do
    assert @product.logo
    assert @product.logo_original
  end

  test "has logo setup" do
    assert @product.logo_croppable_setup, { width: 200, height: 300 }
  end

  test "can crop a new image" do
    image  = {io: File.open(file_fixture("moon.jpg")), filename: "moon", content_type: "image/jpeg"}
    data   = {x: 20, y: 42, scale: 0.5, background_color: "#BADA55"}

    @product.logo = Croppable::Param.new(image, data)
    @product.save

    assert @product.logo_original.present?

    assert_equal @product.logo_croppable_data.x,                data[:x]
    assert_equal @product.logo_croppable_data.y,                data[:y]
    assert_equal @product.logo_croppable_data.scale,            data[:scale]
    assert_equal @product.logo_croppable_data.background_color, data[:background_color]

    assert_enqueued_with job: Croppable::CropImageJob, args: [@product, :logo]
  end

  test "can crop an existing image" do
    image = {io: File.open(file_fixture("moon.jpg")), filename: "moon", content_type: "image/jpeg"}

    @product.logo_original.attach(image)
    @product.logo_croppable_data = Croppable::Datum.new()
    @product.save

    data = {x: 20, y: 42, scale: 0.5, background_color: "#BADA55"}

    @product.logo = Croppable::Param.new(nil, data)
    @product.save

    assert @product.logo_original.present?

    assert_equal @product.logo_croppable_data.x,                data[:x]
    assert_equal @product.logo_croppable_data.y,                data[:y]
    assert_equal @product.logo_croppable_data.scale,            data[:scale]
    assert_equal @product.logo_croppable_data.background_color, data[:background_color]

    assert_enqueued_with job: Croppable::CropImageJob, args: [@product, :logo]
  end

  test "delete croppable image" do
    moon = {io: File.open(file_fixture("moon.jpg")), filename: "moon",    content_type: "image/jpeg"}
    sun  = {io: File.open(file_fixture("sun.jpg")),  filename: "cropped", content_type: "image/jpeg"}

    @product.logo_original.attach(moon)
    @product.logo_cropped.attach(sun)
    @product.logo_croppable_data = Croppable::Datum.new()
    @product.save

    @product.logo = Croppable::Param.new(nil, {}, delete: true)
    @product.save

    refute @product.logo_original.present?
    refute @product.logo_cropped.present?
    refute @product.logo_croppable_data.present?

    assert_no_enqueued_jobs only: Croppable::CropImageJob
  end

  test "don't crop image if data doens't change" do
    moon = {io: File.open(file_fixture("moon.jpg")), filename: "moon",    content_type: "image/jpeg"}
    sun  = {io: File.open(file_fixture("sun.jpg")),  filename: "cropped", content_type: "image/jpeg"}
    data = {x: 20, y: 42, scale: 0.5, background_color: "#BADA55"}

    @product.logo_original.attach(moon)
    @product.logo_cropped.attach(sun)
    @product.logo_croppable_data = Croppable::Datum.new(data)
    @product.save

    @product.logo = Croppable::Param.new(nil, data)
    @product.save

    assert_no_enqueued_jobs only: Croppable::CropImageJob
  end
end
