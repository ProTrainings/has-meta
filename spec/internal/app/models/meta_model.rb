class MetaModel < ApplicationRecord
  has_meta :target_model, :foo_id, :foo_bar
end