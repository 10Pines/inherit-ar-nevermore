require '../lib/persistence_api/persistence'
require '../lib/persistence_api/memory/memory_persistence'
require '../lib/persistence_api/rails/rails_persistence'
require 'rails'

describe Persistence do

  context "rails persistence" do
    let(:my_class) do
      class MyRailsClass
        include Persistence
      end
    end

    it "should include Persistence::Rails into class" do
      ENV['INHERIT_AR'] = 'rails'
      Rails.stub(:env) { 'development' }
      my_class.ancestors.should include(Persistence::Rails)
      my_class.ancestors.should_not include(Persistence::Memory)
    end
  end

  context "rails persistence" do
    let(:my_class) do
      class MyMemoryClass
        include Persistence
      end
    end
    it "should include Persistence::Memory into class" do
      ENV['INHERIT_AR'] = 'memory'
      my_class.ancestors.should include(Persistence::Memory)
      my_class.ancestors.should_not include(Persistence::Rails)
    end
  end

end