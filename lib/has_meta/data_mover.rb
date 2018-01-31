module HasMeta
  class DataMover
    def initialize table, attribute, type, key
      @table      = table
      @attribute  = attribute
      @key        = key
      @type       = type
    end

    def execute
      
      insert          = Arel::Nodes::InsertStatement.new
      insert.relation = destination_table
      insert.columns  = destination_columns
      insert.values   = Arel::Nodes::SqlLiteral.new source_values
      # There seems to be a bug with earlier versions of Arel where multiple values aren't supported
      # insert.select   = source_select.where(source_conditions)
      
      ActiveRecord::Base.connection.execute insert.to_sql if migrateable?

      self
    end
    
    def generate_migration
      # to implement
    end
    
    private
    
    attr_accessor :abort
    attr_reader :table, :attribute, :key, :type
    
    def source_values
      migrateable_source_values
        .reduce(" VALUES ") {|acc, row| acc += format_values row}[0...-1]
    end
    
    def migrateable_source_values
      if type.to_s == 'text'      
        source_model.where.not(:"#{attribute}" => [nil, ''])
      else
        source_model.where(source_table[:"#{attribute}"].not_eq(nil))
      end
    end
    
    def migrateable?
      migrateable_source_values.present?
    end
    
    def format_values row
      "('#{table.classify.constantize.name}', #{row.id}, '#{key}', #{escape(row.send(:"#{attribute}"))}, '#{Time.now}'),"
    end
    
    def escape value
      if ['text', 'date'].include? type.to_s
        "'#{value}'"
      else
        value
      end
    end
    
    def source_model
      table.classify.constantize
    end
    
    def source_table
      @source_table ||= Arel::Table.new(table) 
    end
    
    def source_select
      source_table.project(
        Arel.sql("\'#{table.classify.constantize.name}\'"),   # :meta_model_type
        source_table[:id],                                    # :meta_model_id
        Arel.sql("\'#{key}\'"),                               # :key
        source_table[:"#{attribute}"],                        # :integer_value (ex.)
        Arel::Nodes::NamedFunction.new("NOW", [])             # :created_at
      )
    end
    
    def source_conditions
      source_table[:"#{attribute}"].not_in([nil, ''])
    end
    
    def destination_table
      @destination_table ||= HasMeta::MetaData.arel_table
    end
    
    def destination_columns
      [
        destination_table[:meta_model_type],
        destination_table[:meta_model_id],
        destination_table[:key],
        destination_table[:"#{type}_value"],
        destination_table[:created_at],
      ]
    end
    
  end
end