module Persistence

  def self.included(klass)
    klass.send :include, persistence_strategy
  end

  def self.persistence_strategy
    if ENV['INHERIT_AR'] == 'memory'
      require 'active_support/core_ext/string/inflections'
      require File.dirname(__FILE__) + '/memory/memory_persistence'
      require File.dirname(__FILE__) + '/memory/relation'
      require File.dirname(__FILE__) + '/memory/condition'
      Persistence::Memory
    else
      require 'active_record'
      require File.dirname(__FILE__) +  '/rails/rails_persistence'
      Persistence::Rails
    end
  end
end