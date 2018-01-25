module HasMeta
  class MetaQuery
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