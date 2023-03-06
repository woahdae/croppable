module Croppable
  class Param
    attr_accessor :image, :data, :delete

    def initialize(image, data, delete)
      @image = image
      @delete = delete
      @data  = {
        x:                data[:x],
        y:                data[:y],
        scale:            data[:scale],
        background_color: data[:background_color]
      }
    end
  end
end
