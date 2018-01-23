module HasMeta
  class MetaData < ::ActiveRecord::Base
    
    belongs_to :meta_model, polymorphic: true

    def value

      return text_value if text_value!=nil
      return integer_value if integer_value!=nil
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
        self.integer_value = val
      when :decimal
        self.decimal_value = val
      else
        self.text_value = val
      end
      self.save
    end
    
    def clear_values
      self.date_value = nil
      self.integer_value = nil
      self.decimal_value = nil
      self.text_value = nil
    end
    
    def self.resolve_data_type value
      case value
      when ->(x) {x.kind_of? Integer}
        # TODO: dynamically check for a range error (is this a ruby thing or mysql thing?)
        if value < 2000000000
          return :integer, value
        else
          # Force data_type to text if the value is greater than the allowed valueue for an int
          return :text, value.to_s
        end
      when ->(x) {x.kind_of? Float}
        return :decimal, value
      when ->(x) {x.kind_of? Date}
        return :date, value
      else
        return :integer, value.to_i if value =~ /^-?\d+$/
        return :decimal, value.to_f if value =~ /^-?\d*\.\d+$/
        return :text, value
      end            
    end
    
    def resolve_data_type value
      self.class.resolve_data_type value
    end
    
    def self.generate_value_hash value
      data_type, value = resolve_data_type value
      {"#{data_type}_value": value}
    end
    
  end
end
