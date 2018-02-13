module HasMeta
  module InstanceMethods
    
    def meta_get key
      return self.meta_attributes_pending_save[key][:value] if self.meta_attributes_pending_save.try(:[], key).present?

      self.meta_data.where(key: key.to_s).try(:first).try(:value)
    end
  
    def meta_set key, value, options={}
      return meta_destroy key if value.nil? or value == ''
      if self.persisted?
        meta = self.meta_data.where(key: key.to_s).first_or_create
        meta.send :value=, value, options
        meta
      else
        add_to_pending_save key => {value: value, options: options}
      end
    end
  
    def add_to_pending_save args
      self.meta_attributes_pending_save ||= {}
      self.meta_attributes_pending_save.merge!(args)
    end

    def save_pending_meta_attributes
      self.meta_attributes_pending_save.each { |key, v| meta_set! key, v[:value], v[:options] }
      self.meta_attributes_pending_save.clear
    end

    def meta_set! key, value, options={}
      result = meta_set(key, value, options)
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
