ActiveRecord::Schema.define version: 0 do
  create_table :meta_data, force: true do |t|
    t.string    :meta_model_type
    t.integer   :meta_model_id
    t.string    :key
    t.text      :text_value
    t.integer   :int_value
    t.decimal   :decimal_value, precision: 6, scale: 2
    t.date      :date_value
  end
  
  create_table :meta_models, force: true do |t|
    t.string :name
    t.string :type
  end
  
  create_table :target_models, force: true do |t|
    t.string :name
  end
end