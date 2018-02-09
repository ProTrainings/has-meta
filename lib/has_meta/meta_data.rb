module HasMeta
  class MetaData < ::ActiveRecord::Base
    
    belongs_to :meta_model, polymorphic: true

    attr_accessor :value
    attr_reader :data_type

    def value
      @value ||= convert_type value_attributes.compact.values.pop
    end
    
    def value= value
      @data_type, @value = resolve_data_type! value
      set_attribute
    end
        
    def self.generate_value_hash *values
      # values = 'some text'
      # values = ['some text', 'some other text']
      # values = ['some text', 'some other text', 9]
      if values.size == 1
        # {text_value: 'some text'}
        value_hash_for values.pop
      else
        # ['some text', 'some other text', 9]
        # [{text_value: 'some text'}, {text_value: 'some other text'}, {integer_value: 9}]
        # {:text_value=>[{:text_value=>"some text"}, {:text_value=>"some other text"}], :integer_value=>[{:integer_value=>9}]}
        # values.map { |value| value_hash_for value }.group_by { |x| x.keys.first }.map {|k, v| {k => v.map {|x| x.values.first}}}
        values
          .map { |value| value_hash_for value }
          .group_by { |x| x.keys.first }
          .reduce({}) do |acc, hash|
            key, value = *hash 
            acc.merge({key => value.size == 1 ? value.first.values.first : value.map {|x| x.values.first}})
          end
          # .map {|k, v| {k => v.map {|x| x.values.first}}}
      end
    end
    
    private
    
    def convert_type value
      begin
        if value =~ /^-?\d+/ and value.to_i > 2000000000
          value.to_i
        elsif value =~ /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} (\+|-)\d{4}$/
          value.to_time
        elsif value =~ /^\d{4}-\d{2}-\d{2}$/
          value.to_date
        else
          value
        end
      rescue
        value
      end
    end

    def self.value_hash_for value
      data_type, value = resolve_data_type! value
      {"#{data_type}_value": value}
    end
        
    def self.resolve_data_type! value
      case value
      when ->(x) {x.kind_of? Integer}
        # TODO: dynamically check for a range error (is this a ruby thing or mysql thing?)
        if value < 2000000000
          return :integer, value
        else
          return :text, value.to_s
        end
      when ->(x) {x.kind_of? Float}
        return :decimal, value
      when ->(x) {x.kind_of? Date}
        return :date, value
      when ->(x) {x.acts_like? :time}
        return :datetime, value
      when ->(x) {x.respond_to? :id}
        return :integer, value.id
      else
        return :integer, value.to_i if value =~ /^-?\d+$/
        return :decimal, value.to_f if value =~ /^-?\d*\.\d+$/
        return :date, value.to_date if date_try_convert value
        return :datetime, value.to_datetime if datetime_try_convert value
        return :text, value
      end            
    end
    
    def self.date_try_convert value
      begin
        value.to_date if value =~ /^\d{4}-\d{2}-\d{2}$/
      rescue
        nil
      end
    end

    def self.datetime_try_convert value
      begin
        value.to_datetime if value =~ /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} (\+|-)\d{4}$/
      rescue
        nil
      end
    end
    
    def resolve_data_type! value
      self.class.resolve_data_type! value
    end
    
    def value_attributes 
      self.attributes.select do |k, _|
        k =~ /_value/
      end
    end
    
    def reset_values
      value_attributes.keys.each do |attribute|
        self[attribute] = nil
      end
    end
    
    def set_attribute
      reset_values
      self[:"#{@data_type}_value"] = @value
    end
    
  end
end
