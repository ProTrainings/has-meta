namespace :has_meta_engine do

    desc 'Move data from existing table to meta_data table'
    task :data_mover, [:table, :attribute, :key, :type] => [:environment] do |t, args|
    
      DataMover.new(*args)
        .execute
        .generate_migration
        
    end
    
  end
  
end