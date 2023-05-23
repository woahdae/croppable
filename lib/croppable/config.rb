module Croppable
  class << self
    def config
      @config ||=
        Config.instance.tap do |config|
          config.default_scale = 1
          config.headless_fit = :contain
          config.headless_bg = '#ffffff'
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
    attr_accessor :headless_fit
    attr_accessor :headless_bg
    attr_accessor :image_quality
    attr_accessor :crop_backend

    def crop_backend=(value)
      raise "Invalid crop backend: #{value}"\
        unless %i[vips mini_magick].include?(value)

      @crop_backend = value
    end

    def headless_fit=(value)
      raise "Invalid fit value: #{value}"\
        unless %i[contain cover].include?(value)

      @headless_fit = value
    end
  end
end
