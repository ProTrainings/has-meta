namespace :has_meta_engine do

  desc 'Move data from existing table to meta_data table'
  task :data_mover, [:table, :attribute, :type, :key] => [:environment] do |t, args|
  
    DataMover.new(*args.values).execute

    Rails::Generators.invoke 'active_record:migration', ["Remove#{args.attribute.classify}From#{args.table.classify.pluralize}", "#{args.attribute}:#{args.type}"]
      
  end
  
end