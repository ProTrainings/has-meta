module HasMeta
  module QueryMethods
    def self.included base
      base.extend ClassMethods
    end
  
    module ClassMethods
    
      def with_meta args=nil, options={}
        HasMeta::MetaQuery.new(self, MetaData, args, options).build
      end
    
      def excluding_meta args=nil, options={}
        HasMeta::MetaQuery.new(self, MetaData, args, options.merge(exclude: true)).build
      end
    end  
  end
end
