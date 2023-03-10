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

The asset_host config needs to be set on every environment
```ruby
config.asset_host = "http://localhost:3000"
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
has_croppable :logo, width: 300, height: 300
```

Add croppable_field to your form
```ruby
form.croppable_field :logo
```

Update controller strong paramenters to permit each croppable parameter
```ruby
params.require(:model).permit(..., :logo)
```

Display cropped image in your view
```ruby
image_tag model.logo if model.logo.present?
```

Original image can be accessed in \<croppable\>_original
```ruby
model.logo_original
```

NOTE: Images are cropped in a background job after model gets saved so they might not be immediately available

## Contributing

Run all test
```bash
rails test
rails app:test:system
```

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
