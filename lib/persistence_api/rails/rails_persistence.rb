require 'active_record'

module Persistence
  module Rails

    def self.included(klass)
      klass.extend(ClassMethods)
      rails_class = Class.new(ActiveRecord::Base)
      rails_class.set_table_name(klass.name.tableize)
      rails_class.class_eval do
        define_method(:is_a?) { |another_class|
          return true if another_class == klass
          return true if another_class.name == klass.name
          return true if another_class.name == 'ActiveRecord::Base'
          return false
        }
      end
      rails_class.instance_eval do
        @class = klass

        def name
          @class.name
        end
        def new(*args)
          rails_object = super(*args)
          new_object = @class.new(*args)
          new_object.instance_variable_set(:@delegate, rails_object)
          new_object
        end
      end
      klass.instance_variable_set(:@delegate_class, rails_class)
    end

    def method_missing(method_name, *args)
      self.class_eval do
        define_method(method_name) do |*args|
          @delegate.send method_name, *args
        end
      end
      if @delegate.nil?
        new_object = self.class.instance_variable_get(:@delegate_class).new(*@args)
        @delegate = new_object.instance_variable_get(:@delegate)
      end
      @delegate.send method_name, *args
    end

    def initialize(*args)
      @args = *args
    end


    module ClassMethods
      def method_missing(method_name, *args)
        ghost = class << self;
          self;
        end
        ghost.instance_eval do
          define_method(method_name) do |*args|
            self.instance_variable_get(:@delegate_class).send method_name, *args
          end
        end
        self.instance_variable_get(:@delegate_class).send method_name, *args
      end
    end
  end
end