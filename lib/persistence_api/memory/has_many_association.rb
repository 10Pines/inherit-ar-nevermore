module Persistence
  class HasManyAssociation

    def initialize(owner, child)
      @owner, @child = owner, child
      @associated_entities = Array.new
    end

    def method_missing(method_name, *args)
      @associated_entities.send(method_name, *args) if @associated_entities.respond_to?(method_name)
    end

    def <<(new_entity)
      @associated_entities << new_entity
      if @owner.persisted?
        new_entity.send("#{@owner.class.name.downcase}=".to_sym, @owner)
      end
    end

    def associated_entities(entities)
      @associated_entities = entities
    end

    def each
      @associated_entities.each { |entity| yield entity }
    end

    def length
      @associated_entities.length
    end

    alias_method :size, :length
    alias_method :count, :length
  end
end