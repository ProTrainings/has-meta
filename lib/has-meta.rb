require 'has_meta/version'
require 'active_record'
require 'active_record/version'
require 'active_support/core_ext/module'
require 'pry'
require 'has_meta/meta_data'
require 'has_meta/meta_query'
require 'has_meta/query_methods'
require 'has_meta/dynamic_methods'
require 'has_meta/instance_methods'

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
  end 
      
end 

ActiveSupport.on_load :active_record do
  extend HasMeta
end
