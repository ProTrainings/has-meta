class AddDatetimeValueToMetaData < ActiveRecord::Migration[4.2]
  def change
    add_column :met_data, :datetime_value, :datetime
end
