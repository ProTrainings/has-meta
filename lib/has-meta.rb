require 'has_meta/version'
require 'active_record'
require 'active_record/version'
require 'active_support/core_ext/module'
require 'pry'
require 'has_meta/meta_data'

module HasMeta
  
  def meta_attributes
    nil
  end
  
  def has_meta(*attributes)
    options = attributes.pop if attributes.last.is_a? Hash
    attributes = attributes.to_a.flatten.compact.map(&:to_sym)

    if self.meta_attributes.present? 
      self.meta_attributes += attributes
    else
      class_attribute :meta_attributes, instance_predicate: false, instance_writer: false
      self.meta_attributes = attributes
    end

    class_eval do
      has_many :meta_data, as: :meta_model, dependent: :destroy, class_name: '::HasMeta::MetaData'
      include HasMeta::InstanceMethods
      include HasMeta::DynamicMethods
    end
  end # ends def has_meta

  module DynamicMethods
    def self.included base
      base.extend ClassMethods
    end
    
    #TODO:
    # Maybe do something like dynamic_method_for attribute, &block where you just pass what to do and if the attribute is false it goes to super
    # Or...find a way to just pass the regex or the block to execute to match and let it do all the work
    # Instance methods (getters and setters)
    def respond_to? method, include_private=false
      attribute = self.meta_attributes.select { |x| method.match /^#{x}(_id)?=?$/ }.pop
      if attribute
        self.class.find_object_from(attribute) ? true : !method.match(/^#{attribute}=?$/).nil?
      else
        super
      end
    end
    
    def method_missing method, *args, &block
      attribute = self.meta_attributes.select { |x| method.match /^#{x}(_id)?=?$/ }.pop
      if attribute
        object = self.class.find_object_from attribute            
        if method =~ /=$/ # setter
          object ? meta_set!(:"#{attribute}_id", args.first.try(:id) || args.first) : meta_set!(attribute, args.first)
        else # getter
          if object
            method =~ /_id$/ ? meta_get(:"#{attribute}_id") : object.find_by_id(meta_get(:"#{attribute}_id"))
          else
            meta_get(attribute)
          end
        end
      else
        super
      end
    end

    module ClassMethods
      # Class methods (find_by_attribute getters)
      def respond_to? method, include_private=false
        attribute = self.meta_attributes.select { |x| method.match(/(?<=^find_by_)#{x}(?=$|(?=_id$))/) }.pop
        if attribute
          find_object_from(attribute) ? !method.match(/_id$/).nil? : !method.match(/#{attribute}$/).nil?
        else
          super
        end
      end
    
      def method_missing method, *args, &block
        # TODO: test should include condition for multiple values being returned (one-to-many relationship)
        # TODO: refactor this to not be as cluttery and dense
        attribute = self.meta_attributes.select { |x| method.match /(?<=^find_by_)#{x}(?=$|(?=_id$))/ }.pop
        if attribute
          object = find_object_from(attribute)
          if object and method =~ /_id$/
            conditions = {key: "#{attribute}_id", meta_model_type: self}.
              merge! MetaData.generate_value_hash(args.first)
              MetaData.where(conditions).map do |x|
                self.find_by_id(x.meta_model_id)
              end
          elsif !object
            conditions = {key: "#{attribute}", meta_model_type: self}.
              merge! MetaData.generate_value_hash(args.first)
            MetaData.where(conditions).map do |x|
              self.find_by_id(x.meta_model_id)
            end
          else
            super
          end
        else
          super
        end
      end
   
      def find_object_from attribute
        begin
          attribute.to_s.classify.constantize
        rescue
          nil
        end
      end
    end
  end # ends module DynamicMethods

  module InstanceMethods
 
    def meta_get key
      self.meta_data.where(key: key.to_s).first.value
    end
    
    def meta_set key, value
      return meta_destroy key if value.nil? or value == ''
      
      meta = self.meta_data.where(key: key.to_s).first_or_create
      meta.value = value
      meta
    end
    
    def meta_set! key, value
      meta_set(key, value).save
    end
      
    def meta_destroy key
      self.meta_data.where(key: key).destroy_all
    end
      
    def list_meta_keys
        meta = MetaData.where(:meta_model_type => self.class.arel_table.name, :meta_model_id => self.id).pluck(:key)
    end
    
    def remove_meta(key)
      MetaData.where(:key => key, :meta_model_type => self.class.arel_table.name, :meta_model_id => self.id).destroy_all
    end
      
  end #ends module InstanceMethods
        
    private
    
    def update_meta_attributes_on_save
      if yield and @meta_attributes_to_save.present?
        @meta_attributes_to_save.each { |k, v| self.public_send("#{k}=", v) } 
        @meta_attributes_to_save = nil
      end
    end
        
end #ends module HasMeta

#ActiveRecord::Base.send(:include, 'HasMeta')
ActiveSupport.on_load :active_record do
  extend HasMeta
end
