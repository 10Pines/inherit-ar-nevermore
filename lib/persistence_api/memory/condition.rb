module Persistence
  #TODO: Can we parse conditions with Arel or another gem?
  class Condition

    OPERATORS = {'=' => '==', '<' => '<', '>' => '>', '<>' => '!=', '<=' => '<=', '>=' => '>='}

    def initialize(str_condition)
      operator_match = str_condition.match /#{OPERATORS.keys.join('|')}/
      @operator = OPERATORS[str_condition.slice(operator_match.begin(0), operator_match.length).strip]
      @field = str_condition.slice(0, operator_match.begin(0)).strip
      @expression = str_condition.slice(operator_match.end(0), str_condition.length).strip
    end

    def evaluate(entity)
      attribute = entity.send @field
      eval "#{sanitize_value(attribute)}#{@operator}#{@expression}"
    end

    private

    def sanitize_value(value)
      value.is_a?(String) ? "'#{value}'" : value
    end
  end
end