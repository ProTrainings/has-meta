class HasMetaMigration < ActiveRecord::Migration

  def self.up
    create_table :meta_data do |t|
      
      t.references :meta_model, polymorphic: true
      
      t.string :key
      t.string :text_value
      t.integer :integer_value
      t.decimal :decimal_value, 
        :precision => 6, 
        :scale => 2
      t.date :date_value

      t.timestamps
    end
    
    add_index :meta_data, [:meta_model_type, :meta_model_id, :key]
  end

  def self.down
    drop_table :meta_data
  end

end