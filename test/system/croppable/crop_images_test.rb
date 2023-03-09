require "application_system_test_case"

class CropImagesTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  test "upload an image to crop on new instance" do
    visit new_product_url

    assert_selector ".croppable-droparea"

    find(".croppable-droparea").drop file_fixture("moon.jpg").to_path

    has_no_selector? ".croppable-droparead"
    assert_selector  "cropper-canvas"
    assert_selector  ".croppable-controls"

    click_button "Create Product"

    product = Product.last
    
    assert product.logo_original.present?
    assert product.logo_croppable_data.present?
    assert product.logo_croppable_data.x.present?
    assert product.logo_croppable_data.y.present?
    assert product.logo_croppable_data.scale.present?
    assert product.logo_croppable_data.background_color.present?

    assert_enqueued_with job: Croppable::CropImageJob, args: [product, :logo]
  end

  test "upload a new image to crop on an existing instance" do
    image   = {io: File.open(file_fixture("moon.jpg")), filename: "moon", content_type: "image/jpeg"}
    data    = {x: 20, y: 42, scale: 0.5, background_color: "#BADA55"}
    logo    = Croppable::Param.new(image, data)
    product = Product.new(name: :moon, logo: logo)
    product.save

    clear_enqueued_jobs

    visit edit_product_url product

    has_no_selector? ".croppable-droparead"
    assert_selector  "cropper-canvas"
    assert_selector  ".croppable-controls"

    assert_equal find(".croppable-bgcolor").value, "#bada55"

    click_button class: "croppable-delete"

    has_no_selector? "cropper-canvas"
    has_no_selector? ".croppable-controls"

    find(".croppable-droparea").drop file_fixture("sun.jpg").to_path

    has_no_selector? ".croppable-droparead"
    assert_selector  "cropper-canvas"
    assert_selector  ".croppable-controls"

    fill_in class: "croppable-bgcolor", with: "#c0ffee"

    click_button "Update Product"

    product.reload

    assert_equal product.logo_original.filename, "sun.jpg"
    
    assert       product.logo_croppable_data.present?
    assert_equal product.logo_croppable_data.x, -28
    assert_equal product.logo_croppable_data.y, 22
    assert_equal product.logo_croppable_data.scale, 1.171875
    assert_equal product.logo_croppable_data.background_color, "#c0ffee"

    assert_enqueued_with job: Croppable::CropImageJob, args: [product, :logo]
  end

  test "delete a croppable image" do
    image   = {io: File.open(file_fixture("moon.jpg")), filename: "moon", content_type: "image/jpeg"}
    data    = {x: 20, y: 42, scale: 0.5, background_color: "#BADA55"}
    logo    = Croppable::Param.new(image, data)
    product = Product.new(name: :moon, logo: logo)
    product.save

    visit edit_product_url product

    click_button class: "croppable-delete"

    click_button "Update Product"

    product.reload

    refute product.logo_original.present?
    refute product.logo_cropped.present?
    refute product.logo_croppable_data.present?
  end
end
