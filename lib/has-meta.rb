require "has_meta/version"
module HasMeta
require 'active_record'
require 'active_record/version'
require 'active_support/core_ext/module'
require 'pry'
require 'has_meta/meta_data'
  
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
        # self.around_save    :update_meta_attributes_on_save

        # Stuff under here can me put into it's own module and then included/extended to make it all nice and clean
        
        
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
              object ? meta(:"#{attribute}_id", args.first.try(:id) || args.first) : meta(attribute, args.first)
            else # getter
              if object
                method =~ /_id$/ ? meta(:"#{attribute}_id") : object.find_by_id(meta(:"#{attribute}_id"))
              else  
                meta(attribute)
              end
            end
          else
            super
          end
        end

        # Class methods (find_by_attribute getters)
        def self.respond_to? method, include_private=false
          attribute = self.meta_attributes.select { |x| method.match(/(?<=^find_by_)#{x}(?=$|(?=_id$))/) }.pop
          if attribute
            find_object_from(attribute) ? !method.match(/_id$/).nil? : !method.match(/#{attribute}$/).nil?
          else
            super
          end
        end
        
        def self.method_missing method, *args, &block
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
       
        def self.find_object_from attribute
          begin
            attribute.to_s.classify.constantize
          rescue
            nil
          end
        end
        
        #TODO:
        # Maybe do something like dynamic_method_for attribute, &block where you just pass what to do and if the attribute is false it goes to super
        # Or...find a way to just pass the regex or the block to execute to match and let it do all the work
      
      end
    end # ends def has_meta

  module InstanceMethods
 
    # data_type [Text, Integer, Decimal, Date]
    def meta(key, val={})
      return false unless self.persisted?
      case val
      when {}
        meta = self.meta_data.where key: key.to_s
        return meta.present? ? meta.last.value : nil
      when nil, ''
        return MetaData.where(:key => key.to_s, :meta_model_type => self.class.arel_table.name, :meta_model_id => self.id).destroy_all
      end
      
      #we are setting a value
      meta = self.meta_data.where(key: key.to_s).first_or_create
      # meta = MetaData.where(:key => key, :meta_model_type => self.class.arel_table.name, :meta_model_id => self.id).first_or_create
      
      data_type = MetaData.resolve_data_type val
      if data_type == :integer and !val.is_a? Integer
        val = val.to_i
      elsif data_type == :decimal and !val.is_a? Float
        val = val.to_f
      end
      
      meta.save_value!(data_type, val)
    end #ends def meta
      
    def list_meta_keys
        meta = MetaData.where(:meta_model_type => self.class.arel_table.name, :meta_model_id => self.id).pluck(:key)
    end
    
    def remove_meta(key)
      MetaData.where(:key => key, :meta_model_type => self.class.arel_table.name, :meta_model_id => self.id).destroy_all
    end
      
  end #ends module InstanceMethods
    
    module Helper      
      def self.cached_model_names
        Rails.cache.fetch("model_names", :expires_in => 1.hour) {ApplicationRecord.descendants}
      end
    end #ends module Helper
    
    # This needs to live in HasMeta so that it's available to all active record instances
    # define_method :meta_attributes do |inherit=false|
    #   begin
    #     self.class.meta_attributes(inherit)
    #   rescue
    #     nil
    #   end
    # end
    
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

 #module ActiveModel
 #  module AttributeAssignment
 #    alias :assign_attributes_original :assign_attributes
 #    
 #    def filter_meta_attributes(attributes)
 #      meta_attributes_to_save = {}
 #      self.meta_attributes(true).each do |k|
 #        if [k, k.to_s, "#{k.to_s}_id", :"#{k.to_s}_id"].any? {|x| attributes.key? x }
 #          if self.respond_to? :"#{k.to_s}_id"
 #            meta_key = "#{k.to_s}_id"
 #            meta_value = attributes[k].id
 #          else
 #            meta_key = k
 #            meta_value = attributes[k]
 #          end
 #          meta_attributes_to_save[meta_key] = meta_value
 #          attributes.delete(k.to_s) unless attributes.delete(k)
 #        end
 #      end
 #      @meta_attributes_to_save = meta_attributes_to_save if meta_attributes_to_save.present?
 #      assign_attributes_original attributes
 #    end
 #    
 #    alias :assign_attributes :filter_meta_attributes
 #  end
 #end

#ActiveRecord::Base.send(:include, 'HasMeta')
ActiveSupport.on_load :active_record do
  extend HasMeta
end
