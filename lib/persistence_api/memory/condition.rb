module Persistence
  class BinaryCondition

    OPERATORS = {'=' => '==', '<' => '<', '>' => '>', '<>' => '!=', '<=' => '<=', '>=' => '>='}

    def self.from_string(expression, *placeholders)
      string_condition = replace_placeholders(expression, placeholders)
      operator_match = string_condition.match /#{OPERATORS.keys.join('|')}/
      operator = OPERATORS[string_condition.slice(operator_match.begin(0), operator_match.length).strip]
      field = string_condition.slice(0, operator_match.begin(0)).strip
      expected_value = string_condition.slice(operator_match.end(0), string_condition.length).strip
      self.new(field, operator, expected_value)
    end

    def self.equality(field, value)
      self.new(field, '==', value)
    end

    def initialize(field, operator, value)
      @field, @operator, @expected_value = field, operator, value
    end

    def evaluate(entity)
      actual_value = entity.send @field
      eval "#{sanitize_value(actual_value)}#{@operator}#{sanitize_value(@expected_value)}"
    end

    private

    def self.replace_placeholders(expression, placeholders)
      placeholders.flatten.each { |placeholder|
        expression = expression.sub(/\?/, "'#{placeholder}'")
      }
      expression
    end

    def sanitize_value(value)
      new_value = value
      if value.is_a?(String)
        new_value = "'#{value}'" unless value.start_with?("'")
      end
      new_value
    end
  end

  class InCondition

    def initialize(field, value_list)
      @field, @value_list = field, value_list
    end

    def evaluate(entity)
      attribute = entity.send @field
      @value_list.any? { |expected_value|
        attribute == expected_value
      }
    end

    def sanitize_value(value)
      value.is_a?(String) ? "'#{value}'" : value
    end
  end

  class JoinCondition
    def initialize(association, conditions)
      @association = association
      @wheres = conditions.keys.map {|field|
        BinaryCondition.equality(field, conditions[field])
      }
    end

    def evaluate(entity)
      assoc_entity = entity.send(@association.to_s.pluralize) || entity.send(@association.to_s.singularize)
      @wheres.all? { |condition|
        condition.evaluate(assoc_entity)
      }
    end

  end
end