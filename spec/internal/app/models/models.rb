class MetaModel < ActiveRecord::Base
  has_meta :target_model, :foo_id, :foo_bar
end

class SubMetaModel < MetaModel
  has_meta :bar
end

class TargetModel < ActiveRecord::Base
end