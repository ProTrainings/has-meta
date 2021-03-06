namespace :has_meta_engine do

  desc 'Move data from existing table to meta_data table'
  task :data_mover, [:table, :attribute, :type, :key] => [:environment] do |t, args|

    HasMeta::DataMover.new(*args).execute
  
  end
  
end