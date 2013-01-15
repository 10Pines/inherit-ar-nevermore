require '../lib/persistence_api/persistence'
require '../lib/persistence_api/memory/memory_persistence'
require '../lib/persistence_api/rails/rails_persistence'
require 'rails'

describe Persistence do

  let(:my_class) do
    class MyClass
      include Persistence
    end
  end

  it "should include Persistence::Memory into class" do
    ENV['INHERIT_AR'] = 'memory'
    my_class.ancestors.should include(Persistence::Memory)
    my_class.ancestors.should_not include(Persistence::Rails)
  end

  it "should include Persistence::Rails into class" do
    ENV['INHERIT_AR'] = 'rails'
    Rails.stub(:env) { 'development' }
    ancestors = my_class.ancestors
    ancestors.should include(Persistence::Rails)
  end
end