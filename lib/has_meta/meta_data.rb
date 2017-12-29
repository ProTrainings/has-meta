module HasMeta
  class MetaData < ApplicationRecord
    
    def value
      
      return text_value if text_value!=nil
      return boolean_value if boolean_value!=nil
      return int_value if int_value!=nil
      return date_value if date_value!=nil
      return decimal_value if decimal_value!=nil    
          
      return nil
    end
    
    def save_value!(data_type, val)
      clear_values
      
      case data_type
      when :date
        self.date_value = val
      when :integer
        self.int_value = val
      when :decimal
        self.decimal_value = val
      when :boolean
        self.boolean_value = val
      else
        self.text_value = val
      end
      self.save
    end
    
    def clear_values
      self.date_value = nil
      self.int_value = nil
      self.decimal_value = nil
      self.boolean_value = nil
      self.text_value = nil
    end
    
  end
end
