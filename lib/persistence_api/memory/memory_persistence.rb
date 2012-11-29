require 'active_record/errors'

module Persistence
  module Memory

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    def initialize(attributes = {})
      @attributes = attributes
    end

    def persisted?
      @persisted
    end

    def save
      self.class.new_entity(self)
      @persisted = true
    end

    def save!
      self.class.new_entity(self)
      @persisted = true
    end

    def method_missing(method_name, *args)
      puts "#{method_name} not defined"
      if method_name.to_s =~ /[^=]=[^=]/
        @attributes[method_name.gsub('=', '')]=*args
      else
        @attributes[method_name]
      end

    end

    def destroy
      self.class.remove_entity(self)
      @persisted = false
    end

    def id
      self.class.saved_entities.index(self)
    end

    module ClassMethods

      def destroy_all
        saved_entities.clear
      end

      def delete_all
        destroy_all
      end

      def new_entity(entity)
        saved_entities << entity
      end

      def remove_entity(entity)
        saved_entities.delete(entity)
      end

      def method_missing(method_name, *args)
        puts "missing #{method_name}"
        if method_name.to_s =~ /find_by.*/
          attribute = method_name.to_s.gsub('find_by_', '')
          saved_entities.find { |entity|
            entity.send(attribute.to_sym) == args.first
          }
        end
      end

      def find(id)
        result = saved_entities.at(id)
        raise ActiveRecord::RecordNotFound.new("Couldn't find #{self.class.name} with ID #{id}") if result.nil?
        result
      end

      def belongs_to(other_model)
      end

      def has_one(other_model)
      end

      def create(attributes)
        new_instance = self.new(attributes)
        new_instance.save
        new_instance
      end

      def where(expression)
        Relation.new(self).where(expression)
      end

      def saved_entities
        @saved_entities ||= []
      end

    end
  end
end