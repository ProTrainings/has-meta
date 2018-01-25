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
      include HasMeta::QueryMethods
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
  
  module MetaQueries
    class MetaQueryBase
      def initialize meta_model, meta_data, conditions, options={}
        @meta_model = meta_model
        @meta_data  = meta_data
        @conditions = conditions
        @options    = options
      end
      
      def build
        @meta_model
          .joins(for_each_meta_key)
          .where(conditions_for_keys_and_values)
      end
      
      private
      
      attr_reader :meta_model, :meta_data, :conditions, :options
      
      def meta_model_arel_table
        @meta_model_arel_table ||= @meta_model.arel_table
      end
      
      def meta_data_arel_table
        @meta_data_arel_table ||= @meta_data.arel_table
      end
      
      def meta_data_aliases
        @meta_data_aliases = @conditions.keys
          .map.with_index do |key, i|
            {key => meta_data_arel_table.alias("#{key}_join")}
          end
      end
      
      def for_each_meta_key        
        meta_data_aliases.reduce(meta_model_arel_table) { |acc, meta_data_alias_hash|
          key, meta_data_alias = *meta_data_alias_hash.first
          
          acc
            .join(meta_data_alias, join_type)
            .on(on_conditions meta_data_alias, key)
        }.join_sources
      end
    end
        
    class WithMeta < MetaQueryBase
      
      def join_type
        if options[:exclude] or options[:any] 
          Arel::Nodes::OuterJoin 
        else 
          Arel::Nodes::InnerJoin
        end
      end
      
      def on_conditions table_alias, key
        type_condition = table_alias[:meta_model_type].eq(meta_model)
        id_condition = table_alias[:meta_model_id].eq(meta_model_arel_table[:id])
        key_condition = table_alias[:key].eq(resolve_key key)
        
        type_condition.and(id_condition).and(key_condition)
      end
      
      def conditions_for_keys_and_values 
        @conditions.values.map.with_index do |values, i|
          
          conditions_for_values(meta_data_aliases[i].values.pop, values)
            .reduce { |acc, x| acc.or(x) } 

        end
        .reduce { |acc, x| options[:any] ? acc.or(x) : acc.and(x) } 
      end
      
      def resolve_key key
        meta_model.find_object_from(key) ? "#{key}_id" : key
      end
      
      def conditions_for_values meta_data_alias, values
        MetaData.generate_value_hash(*values).map do |column, value| 
          if options[:exclude]
            meta_data_alias[column].not_in(value)
          else
            meta_data_alias[column].in(value)
          end
        end
      end
    end
  end
  
  module QueryMethods
    def self.included base
      base.extend ClassMethods
    end
    
    module ClassMethods
      
      def with_meta args=nil, options={}
        HasMeta::MetaQueries::WithMeta.new(self, MetaData, args, options).build
      end
      
      def excluding_meta args=nil, options={}
        HasMeta::MetaQueries::WithMeta.new(self, MetaData, args, options.merge(exclude: true)).build
      end
    end  
      
  end
        
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
