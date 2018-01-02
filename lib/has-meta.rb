require "has_meta/version"
module HasMeta
  #extend ActiveSupport::Concern

#  def self.included(base)
#    base.extend(ClassMethods)
#  end
  
  # module ClassMethods
    # This needs to live outside of has_meta so that it's available to all classes
    def meta_attributes(inherit=false)
      begin
        if inherit
          self.class_variables.select{ |x| x =~ /meta_attributes/}
            .map{|v| self.class_variable_get v }
            .flatten
        else
          self.class_variable_get :"@@meta_attributes_#{self.name.underscore}"
        end
      rescue
        nil
      end
    end
    
    # calling has_meta without arguments will allow access to the meta method in the model
    # calling has_meta with arguments will allow access to meta and define getter/setter
    # convenience methods for the attributes passed in (as symbols)
    def has_meta(*attributes)
      class_eval do
        has_many :meta_data, as: :meta_model, dependent: destroy, class_name: '::HasMeta::MetaData'
        include HasMeta::InstanceMethods
      end
      
      options = attributes.pop if attributes.last.is_a? Hash
      
      if attributes.present?
      
        self.around_save    :update_meta_attributes_on_save
        self.after_destroy  :delete_meta_attributes_on_destroy
      
        self.class_variable_set :"@@meta_attributes_#{self.name.underscore}", attributes
      
        attributes.each do |attribute|
          begin
            klass = const_get(attribute.to_s.classify)
            klass = nil unless klass.in? Helper.cached_model_names
            klass
          rescue 
            klass = nil
          end
          
          if klass
            define_method :"#{attribute}" do
              klass.public_send(:find_by_id, self.meta("#{attribute}_id"))
            end
          
            define_method :"#{attribute}_id" do
              self.meta("#{attribute}_id")
            end
          
            define_method :"#{attribute}=" do |value|
              self.meta("#{klass.to_s.underscore}_id", value.nil? ? nil : value.id)
            end
        
            define_method :"#{attribute}_id=" do |value|
              self.meta("#{klass.to_s.underscore}_id", value)
            end
        
            define_singleton_method :"find_by_#{attribute}_id" do |value|
              data_type = Helper.get_type value
              data_type = :int if data_type == :integer
              self.find_by_id(Metadata.where(meta_model_type: self.arel_table.name, key: "#{attribute}_id", "#{data_type.to_s}_value": value ).first.try(:meta_model_id))
            end
          
          else
            define_method :"#{attribute}" do
              self.meta(attribute)
            end
          
            define_method :"#{attribute}=" do |value|
              self.meta(attribute, value)
            end

            define_singleton_method :"find_by_#{attribute}" do |value|
              data_type = Helper.get_type value
              data_type = :int if data_type == :integer
              self.find_by_id(Metadata.where(meta_model_type: self.arel_table.name, key: attribute, "#{data_type.to_s}_value": value ).first.try(:meta_model_id))
            end
          end
        
        end # ends attributes.each
      end # ends if attributes.present?
    end # ends def has_meta
  # end # ends module ClassMethods

  module InstanceMethods
 
    # data_type [Text, Integer, Decimal, Date]
    def meta(key, val={})
      return false unless self.persisted?
      case val
      when {}
        meta = Metadata.where(:key => key, :meta_model_type => self.arel_table.name, :meta_model_id => self.id)
        return meta.present? ? meta.last.value : nil
      when nil, ''
        return Metadata.where(:key => key, :meta_model_type => self.arel_table.name, :meta_model_id => self.id).destroy_all
      end
      
      #we are setting a value
      meta = Metadata.where(:key => key, :meta_model_type => self.arel_table.name, :meta_model_id => self.id).first_or_create
      
      data_type = Helper.get_type val
      if data_type == :integer and !val.is_a? Integer
        val = val.to_i
      elsif data_type == :decimal and !val.is_a? Float
        val = val.to_f
      end
      
      meta.save_value!(data_type, val)
    end #ends def meta
      
    def list_meta_keys
        meta = Metadata.where(:meta_model_type => self.arel_table.name, :meta_model_id => self.id).pluck(:key)
    end
    
    def remove_meta(key)
      Metadata.where(:key => key, :meta_model_type => self.arel_table.name, :meta_model_id => self.id).destroy_all
    end
      
  end #ends module InstanceMethods
    
    module Helper
      def self.get_type val
        if val.kind_of? Integer
          if val < 2000000000
            data_type = :integer
          else
            # Force data_type to text if the val is greater than the allowed value for an int
            return :text
          end
        end
        data_type = :decimal if val.kind_of? Float
        data_type = :date if val.kind_of? Date
        data_type = :boolean if val.kind_of? TrueClass or val.kind_of? FalseClass
        data_type = :text if data_type.blank?
        
        if data_type == :text
          #lets do some casting to see if it fits into integer or decimal...
          if val =~ /\A-{0,1}\d+\Z/
            data_type = :integer unless val.to_i > 2000000000
          end
          if val =~ /\A-{0,1}\d*\.\d+\Z/
            data_type = :decimal
          end
        end
        data_type
      end # ends def get_type
      
      def self.cached_model_names
        Rails.cache.fetch("model_names", :expires_in => 1.hour) {ApplicationRecord.descendants}
      end
    end #ends module Helper
    
    # This needs to live in HasMeta so that it's available to all active record instances
    define_method :meta_attributes do |inherit=false|
      begin
        self.class.meta_attributes(inherit)
      rescue
        nil
      end
    end
    
    private
    
    def update_meta_attributes_on_save
      if yield and @meta_attributes_to_save.present?
        @meta_attributes_to_save.each { |k, v| self.public_send("#{k}=", v) } 
        @meta_attributes_to_save = nil
      end
    end
    
    def delete_meta_attributes_on_destroy
      self.list_meta_keys.each do |k|
        self.remove_meta k 
      end
    end
    
end #ends module HasMeta

module ActiveModel
  module AttributeAssignment
    alias :assign_attributes_original :assign_attributes
    
    def filter_meta_attributes(attributes)
      meta_attributes_to_save = {}
      self.meta_attributes(true).each do |k|
        if [k, k.to_s, "#{k.to_s}_id", :"#{k.to_s}_id"].any? {|x| attributes.key? x }
          if self.respond_to? :"#{k.to_s}_id"
            meta_key = "#{k.to_s}_id"
            meta_value = attributes[k].id
          else
            meta_key = k
            meta_value = attributes[k]
          end
          meta_attributes_to_save[meta_key] = meta_value
          attributes.delete(k.to_s) unless attributes.delete(k)
        end
      end
      @meta_attributes_to_save = meta_attributes_to_save if meta_attributes_to_save.present?
      assign_attributes_original attributes
    end
    
    alias :assign_attributes :filter_meta_attributes
  end
end

#ActiveRecord::Base.send(:include, 'HasMeta')
ActiveSupport.on_load :active_record do
  extend HasMeta
end
