module Persistence

  class Relation
    def initialize(target_class)
      @target_class = target_class
      @wheres = Array.new
      @joins = Hash.new
    end

    def joins(another_model)
      #@joins[another_model] = JoinCondition.new
      self
    end

    def where(expression, *placeholders)
      case expression
      when Hash
        expression.keys.each {|key|
          if expression[key].is_a?(Array)
            @wheres << InCondition.new(key, expression[key])
          elsif expression[key].is_a?(Hash)
            @wheres << JoinCondition.new(key, expression[key])
          else
            @wheres << BinaryCondition.equality(key, expression[key])
          end
        }
      when String
        @wheres << BinaryCondition.from_string(expression, placeholders)
      end
      self
    end

    def method_missing(method_name, *args)
      run_query.send method_name, *args
    end

    private

    def run_query
      result = @target_class.instance_variable_get(:@saved_entities)
      result.select { |entity|
        @wheres.all? { |condition|
          condition.evaluate(entity)
        }
      }
    end
  end
end