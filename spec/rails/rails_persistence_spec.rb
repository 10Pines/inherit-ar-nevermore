require 'active_record'
require '../../lib/persistence_api/rails/rails_persistence'

describe Persistence::Rails do

  class Post
    include Persistence::Rails

    validates :title, :presence => true

    def short_title
      self.title.present? ? self.title[0, Post.short_title_max_chars] : ''
    end

    def self.short_title_max_chars
      5
    end
  end

  before :all do
    Post.establish_connection(:database => 'test_db', :adapter => 'sqlite3')
    Post.connection.execute('create table posts (id integer primary key autoincrement, title varchar)')
  end

  after :all do
    File.delete('test_db')
  end

  after :each do
    Post.delete_all
  end

  context "should be saved" do
    it "creates instance" do
      post = Post.create!(:title => 'my post')
      saved_post = Post.find(post.id)
      saved_post.id.should == post.id
    end

    it "new instance" do
      post = Post.new(:title => 'my post')
      post.save
      saved_post = Post.find(post.id)
      saved_post.id.should == post.id
    end
  end

  context "should allow to have its own class methods" do
    Post.short_title_max_chars.should == 5
  end

  context "should allow to have its own instance methods" do
    it "new instance" do
      new_post = Post.new(:title => 'lorem ipsum')
      new_post.short_title.should == 'lorem'
    end

    it "create instance" do
      new_post = Post.create!(:title => 'lorem ipsum')
      new_post.short_title.should == 'lorem'
    end
  end

  it "calls a missing method twice" do
    new_post = Post.new
    new_post.title = 'some title'
    new_post.save
    Post.find(new_post.id).title.should == 'some title'

    new_post.title = 'a new title'
    new_post.save
    Post.find(new_post.id).title.should == 'a new title'
  end

  it "should not be valid" do
    post = Post.new
    post.valid?.should == false
  end

end