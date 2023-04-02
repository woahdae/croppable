module Croppable
  class << self
    def config
      @config ||=
        Config.instance.tap do |config|
          config.default_scale = 1
          config.image_quality = 100

          begin
            require 'ruby-vips'
            config.crop_backend = :vips
          rescue LoadError
            require 'mini_magick'
            config.crop_backend = :mini_magick
          end
        end
    end
  end

  class Config
    include Singleton

    attr_accessor :default_scale
    attr_accessor :image_quality
    attr_accessor :crop_backend

    def crop_backend=(value)
      raise "Invalid crop backend: #{value}"\
        unless %i[vips mini_magick].include?(value)

      @crop_backend = value
    end
  end
end
