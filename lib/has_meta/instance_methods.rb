module HasMeta
  module InstanceMethods
    
    def meta_get key
      self.meta_data.where(key: key.to_s).try(:first).try(:value)
    end
  
    def meta_set key, value, options={}
      return meta_destroy key if value.nil? or value == ''
    
      meta = self.meta_data.where(key: key.to_s).first_or_create
      # meta.value = value
      meta.send :value=, value, options
      meta
    end
  
    def meta_set! key, value
      result = meta_set(key, value)
      result.respond_to?(:save) ? result.save : result
    end
    
    def meta_destroy key
      self.meta_data.where(key: key).destroy_all
    end
    
    # TODO: Test these
    def list_meta_keys
      self.meta_data.pluck(:keys).uniq
    end
  
    def remove_meta(key)
      self.send(key.to_sym, nil)
    end
    
  end
end
