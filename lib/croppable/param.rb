module Croppable
  class Param
    attr_accessor :image, :data

    def initialize(image, data)
      @image = image
      @data  = {
        x:                data[:x],
        y:                data[:y],
        scale:            data[:scale],
        background_color: data[:background_color]
      }
    end
  end
end
