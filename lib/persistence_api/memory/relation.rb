module Persistence

  class Relation
    def initialize(target_class)
      @target_class = target_class
      @arel = Arel::Table.new(@target_class.class.name.tableize.to_sym)
    end

    def where(expression)
      @arel = @arel.where(expression)
      self
    end

    def method_missing(method_name, *args)
      run_query.send method_name, *args
    end

    private

    def run_query
      result = @target_class.instance_variable_get(:@saved_entities)
      result.select { |entity|
        @arel.wheres.all? { |str_condition|
          Condition.new(str_condition).evaluate(entity)
        }
      }
    end

    def sanitize(condition)
      condition.gsub('=', '==')
    end
  end
end