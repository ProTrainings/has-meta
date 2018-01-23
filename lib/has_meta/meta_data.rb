module HasMeta
  class MetaData < ::ActiveRecord::Base
    
    belongs_to :meta_model, polymorphic: true

    def value

      return text_value if text_value!=nil
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
      else
        self.text_value = val
      end
      self.save
    end
    
    def clear_values
      self.date_value = nil
      self.int_value = nil
      self.decimal_value = nil
      self.text_value = nil
    end
    
    def self.resolve_data_type value
      case value
      when ->(x) {x.kind_of? Integer}
        # TODO: dynamically check for a range error (is this a ruby thing or mysql thing?)
        if value < 2000000000
          :integer
        else
          # Force data_type to text if the value is greater than the allowed valueue for an int
          :text
        end
      when ->(x) {x.kind_of? Float}
        :decimal
      when ->(x) {x.kind_of? Date}
        :date
      else
        return :integer if value =~ /^-?\d+$/
        return :decimal if value =~ /^-?\d*\.\d+$/
        return :text
      end      
    end
    
  end
end
