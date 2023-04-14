module Croppable
  class << self
    def config
      @config ||=
        Config.instance.tap do |config|
          config.default_scale = 1
          config.image_quality = 100
        end
    end
  end

  class Config
    include Singleton

    attr_accessor :default_scale
    attr_accessor :image_quality
  end
end
