module HasMeta
  module DynamicMethods
    def self.included base
      base.extend ClassMethods
    end
  
    #TODO: refactor this
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

      def respond_to? method, include_private=false
        attribute = self.meta_attributes.select { |x| method.match(/(?<=^find_by_)#{x}(?=$|(?=_id$))/) }.pop
        if attribute
          find_object_from(attribute) ? !method.match(/_id$/).nil? : !method.match(/#{attribute}$/).nil?
        else
          super
        end
      end
  
      def method_missing method, *args, &block
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
  end 
end