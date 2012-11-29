module Persistence

  def self.included(klass)
    klass.send :include, persitence_strategy
  end

  def self.persitence_strategy
    if ::Rails.env == 'test'
      Persistence::Memory
    else
      Persistence::Rails
    end
  end
end