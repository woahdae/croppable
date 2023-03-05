class CreateCroppableData < ActiveRecord::Migration[7.0]
  def change
    create_table :croppable_data do |t|
      t.references :croppable, polymorphic: true
      t.string     :name
      t.float      :scale
      t.integer    :x
      t.integer    :y
      t.string     :background_color

      t.timestamps
    end
  end
end
