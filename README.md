# Croppable
Easily crop images in Ruby on Rails with [Cropper.js](https://fengyuanchen.github.io/cropperjs/v2/) integration.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "croppable"
```

## Setup
```bash
bin/rails croppable:install
```

## Manual setup
Install cropperjs JavaScript dependency
```
yarn add cropperjs@next
// or
bin/importmap pin cropperjs@next
```

If you're using importmap add croppable pin to importmap.rb
```ruby
pin "croppable"
```

Import the croppable JavaScript module in your application entrypoint
```js
import "croppable"
```

Import croppable styles in your base stylesheet
```
*= require croppable
```

Install croppable migrations
```
bin/rails croppable:install:migrations
```

## Install [libvips](https://www.libvips.org/install.html)
```bash
brew install vips
```

## Usage
Add has_croppable into your model
```ruby
include Croppable::Model

has_croppable :logo, width: 300, height: 300, scale: 2

# Using predefined variants
has_croppable :logo, width: 300, height: 300, scale: 2 do |attachable|
 attachable.variant :thumb, resize_to_fill: [100, 100]
 attachable.variant :medium, resize_to_fill: [300, 300]
end
```

`width` and `height` are in pixels and required.

`scale: 2` will generate an image twice as big. Useful for retina display monitors. It defaults to 1.

The block is passed to `has_one_attached`, supporting [Rails 7's predefined
variant blocks](https://github.com/rails/rails/pull/39135). If you're using
croppable's `scale` option with a value > 1, you'll have to do the math
yourself for the variant dimensions to match the base scaled image. See the
[ImageProcessing docs](https://github.com/janko/image_processing/tree/master)
for the processing options.

Add croppable_field to your form
```ruby
form.croppable_field :logo
```

Update controller strong paramenters to permit each croppable parameter
```ruby
include Croppable::PermittableParams

params.require(:model).permit(..., logo: croppable_params)
```

Display cropped image in your view
```ruby
image_tag model.logo if model.logo.present?
```

Original image can be accessed in \<croppable\>_original
```ruby
model.logo_original
```

Configuration on global defaults can be done in an initializer:

```ruby
Rails.application.config.to_prepare do
  Croppable.config.default_scale = 2 # default 1
  Croppable.config.image_quality = 80 # default 100
end
```

NOTE: Images are cropped in a background job after model gets saved so they might not be immediately available

### Headless

This gem is built around cropperjs, but in case you need to add images without
the frontend (ex. a bulk import), omitting the crop data will by default do a
"contain" crop and add padding (default white) to the height or width of the
image. A "cover" crop can also be specified, which will crop the height or
width of the image to fill the image dimensions without padding.

Defaults can be changed:

```ruby
Croppable.config.headless_fit = :cover # default :contain
Croppable.config.headless_bg = '#000000' # default #ffffff
```

This can be configured on a per-image basis as well:

```ruby
has_croppable :logo, width: 200, height: 200, headless: { fit: :contain, bg: '#000000' }
has_croppable :hero_image, width: 1000, height: 600, headless: { fit: :cover }
```

Then you can set an image the same way you set an ActiveStorage image:

```ruby
product.logo = { io: File.open('path/to/myimage.jpg'), filename: 'myimage.jpg' }
```

## Contributing

Run all test
```bash
rails test
rails app:test:system
```

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
