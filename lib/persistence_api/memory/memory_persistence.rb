require 'active_record/errors'

module Persistence
  module Memory

    #include ActiveSupport::Callbacks

    def self.included(klass)
      klass.extend(ClassMethods)
      klass.send :include, ActiveModel::Validations
    end

    def initialize(attributes = {})
      @attributes = attributes
    end

    def persisted?
      @persisted
    end

    def save
      self.class.new_entity(self)
      save_associations
      @persisted = true
    end

    def save!
      self.class.new_entity(self)
      save_associations
      @persisted = true
    end

    def update_attribute(attribute, value)
      @attributes[attribute]= value
    end

    def update_attributes(attributes)
      @attributes = @attributes.merge(attributes)
    end

    def method_missing(method_name, *args)
      puts "#{method_name} not defined"
      if method_name.to_s =~ /[^=]=([^=]|$)/
        @attributes[method_name.to_s.gsub('=', '').to_sym]=args[0]
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

    def save_associations
      self.class.has_many_associations.each do |association|
        send(association).each { |associated_entity|
          associated_entity.save
        }
      end
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

      def belongs_to(other_model, options = {})
      end

      def has_one(other_model, options = {})
      end

      def has_and_belongs_to_many(other_model, options = {})
        has_many(other_model)
      end

      def has_many(other_model, options = {})
        relation_name = other_model.to_s.pluralize.to_sym
        has_many_associations << relation_name
        define_method(:lazy_initialize_association) do |relation_name|
          associations = instance_variable_get("@#{relation_name}")
          if associations.nil?
            associations = HasManyAssociation.new(self, relation_name)
            instance_variable_set("@#{relation_name}", associations)
          end
          associations
        end
        define_method(relation_name) do
          lazy_initialize_association(relation_name)
        end
        define_method("#{relation_name}=".to_sym) do |arg|
          associations = lazy_initialize_association(relation_name)
          associations.associated_entities(arg)
          associations
        end
      end

      def create(attributes)
        new_instance = self.new(attributes)
        new_instance.save
        new_instance
      end

      def where(expression, *placeholders)
        Relation.new(self).where(expression, placeholders)
      end

      def joins(another_model)
        Relation.new(self).joins(another_model)
      end

      def saved_entities
        @saved_entities ||= []
      end

      def has_many_associations
        @has_many_associations ||= []
      end

    end
  end
end