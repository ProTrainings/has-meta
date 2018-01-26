namespace :has_meta_engine do
    
  desc 'Move data from existing table to meta_data table'
  task :data_mover, [:table, :attribute, :key, :type] do |t, args|
    
    # What do I have access to when this runs? I might like to put this into a DataMover class to get the mess out of here
    
    # DataMover.new(*args).build_insert
    
    destination_table   = HasMeta::MetaData.arel_table
    destination_columns = [
      destination_table[:meta_model_type],
      destination_table[:meta_model_id],
      destination_table[:key],
      destination_table[:"#{args.type}_value"],
      destination_table[:created_at],
    ]

    source_table        = Arel::Table.new(args.table) 
    source_select       = source_table.project(
      args.table.classify.constantize.name,      # :meta_model_type
      source_table[:id],                    # :meta_model_id
      "\"#{args.key}\"",                             # :key
      source_table[:"#{args.attribute}"],   # :integer_value (ex.)
      Arel::Nodes::NamedFunction.new("NOW", []) # :created_at
    )
    source_conditions   = source_table[:"#{args.attribute}"].not_in([nil, ''])
    
    insert          = Arel::Nodes::InsertStatement.new
    insert.relation = destination_table
    insert.columns  = destination_columns
    # insert.values   = Arel::Nodes::Values.new(hash.values, insert.columns)
    insert.select   = source_select.where(source_table[:"#{args.attribute}"].not_in([nil, '']))
    
    ActiveRecord::Base.connection.execute insert
      
    # And now for a delete query!
    
    # DataMover.new(*args).build_delete
    
  end    
  
end