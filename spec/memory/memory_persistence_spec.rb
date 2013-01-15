require 'active_support/core_ext/string/inflections'
require 'active_model'
require '../../lib/persistence_api/memory/memory_persistence'
require '../../lib/persistence_api/memory/relation'
require '../../lib/persistence_api/memory/condition'
require '../../lib/persistence_api/memory/has_many_association'

describe Persistence::Memory do

  class Comment
    include Persistence::Memory

    has_and_belongs_to_many :authors
  end

  class Author
    include Persistence::Memory

    has_many :posts
    has_and_belongs_to_many :comments
  end

  class Post
    include Persistence::Memory
    belongs_to :author

    validates :title, :presence => true
    validate :title_is_valid

    def short_title
      self.title.present? ? self.title[0, Post.short_title_max_chars] : ''
    end

    def self.short_title_max_chars
      5
    end

    def title_is_valid
      errors.add(:title, "Title is invalid!") if self.title == 'INVALID'
    end
  end

  before :each do
    Post.destroy_all
  end

  context "initialize, save and update" do
    it "create post" do
      post = Post.create(:title => 'a title')
      post.persisted?.should == true
    end

    it "new account credential" do
      post = Post.new(:title => 'a title')
      post.save.should == true
      post.persisted?.should == true
    end

    it "updates one attribute" do
      post = Post.create(:title => 'a title')
      post.update_attribute(:title, 'new title')
      Post.find(post.id).title.should == 'new title'
    end

    it "updates attributes" do
      post = Post.create(:title => 'a title', :description => 'a description', :notes => 'same notes')
      post.update_attributes(:title => 'new title', :description => 'new description', :status => 'updated')
      saved_post = Post.find(post.id)
      saved_post.title.should == 'new title'
      saved_post.description.should == 'new description'
      saved_post.status.should == 'updated'
      saved_post.notes.should == 'same notes'
    end

    it "field assignment" do
      post = Post.new
      post.title = 'a title'
      post.save
      Post.find(post.id).title.should == 'a title'
    end
  end

  context "finders" do
    it "find account credential" do
      Post.create(:title => 'a title')
      post = Post.find_by_title('a title')
      post.should be
      post.persisted?.should == true
    end

    it "find by id present" do
      post = Post.create(:title => 'a title')
      post_new = Post.find(post.id)
      post_new.should be
      post_new.persisted?.should == true
      post_new.title.should == 'a title'
    end

    it "find by id not present" do
      expect {
        Post.find(23)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "validations" do
    it "should not be valid" do
      post = Post.new
      post.valid?.should == false
      post.errors.should have(1).items
      post.errors.first[0].should == :title
    end

    it "supports custom validation methods" do
      post = Post.new(:title => "INVALID")
      post.valid?.should == false
      post.errors.should have(1).items
      post.errors.first[0].should == :title
    end
    it "should be valid" do
      post = Post.new(:title => "VALID")
      post.valid?.should == true
      post.errors.should have(0).items
    end
  end

  context "associations" do
    context "has many" do
      context "not persisted" do
        it "author has many posts - append new post" do
          author = Author.new(:name => 'Emilio')
          post = Post.new(:title => 'test')
          author.posts << post
          author.posts.should have(1).items
          author.posts.last.should == post
          post.author.should be_nil
        end
        it "author has many posts assign posts array" do
          author = Author.new(:name => 'Emilio')
          post = Post.new(:title => 'test')
          author.posts = [post]
          author.posts.should have(1).items
          author.posts.last.should == post
          post.author.should be_nil
        end
      end
      context "persisted" do
        it "author has many posts" do
          author = Author.create(:name => 'Emilio')
          post = Post.new(:title => 'test')
          author.posts << post
          author.posts.should have(1).items
          author.posts.last.should == post
          post.author.should == author
        end
      end

      it "saves associations" do
        author = Author.create(:name => 'Emilio')
        author.posts << Post.new(:title => 'test')
        author.save

        saved_author = Author.find(author.id)
        saved_author.posts.should have(1).items
        saved_author.posts.first.persisted?.should == true
        saved_post = Post.find(saved_author.posts.first.id)
        saved_post.should be
        saved_post.title.should == 'test'
      end
    end
    context "has and belongs to many" do
      it "author has and belongs to many comments" do
        author = Author.create(:name => 'Emilio')
        author.comments << Comment.new(:text => 'nice article!')
        author.comments.should have(1).items
        author.comments.first.author.should == author
      end
    end
    context "belongs to" do
      it "post belongs to author" do
        post = Post.create(:title => 'test', :author => Author.new)
        post.author.should be
      end
    end
  end

  it "class equality" do
    post = Post.create(:title => 'test')
    post.is_a?(Post).should == true
  end

  context "arel" do
    it "joins posts with authors" do
      Post.create(:title => 'a title', :description => 'a description', :author => Author.new(:name => 'Paul'))
      Post.create(:title => 'another title', :description => 'another description', :author => Author.new(:name => 'John'))

      posts = Post.joins(:author).where(:authors => {:name => 'John'})
      posts.count.should == 1
      posts.first.title.should == 'another title'
      posts.first.author.name.should == 'John'
    end

    context "where" do
      it "where simple" do
        Post.create(:title => 'a title', :description => 'same')
        Post.create(:title => 'another title', :description => 'same')

        query = Post.where("title = 'a title'")
        query.count.should == 1
        query.first.title.should == 'a title'

        query = Post.where("description = 'same'")
        query.count.should == 2
        query.first.title.should == 'a title'
        query.last.title.should == 'another title'
      end

      it "where nested" do
        Post.create(:title => 'a title', :description => 'same')
        Post.create(:title => 'another title', :description => 'same')
        Post.create(:title => 'another title', :description => 'another')


        query = Post.where("title = 'a title'").where("description = 'same'")
        query.count.should == 1
        query.first.title.should == 'a title'

        query = Post.where("title = 'another title'").where("description = 'same'")
        query.count.should == 1
        query.first.title.should == 'another title'
        query.first.description.should == 'same'
      end

      it "where with placeholders" do
        Post.create(:title => 'a title', :description => 'same')
        Post.create(:title => 'another title', :description => 'same')
        relation = Post.where("title = ?", 'a title')
        relation.count.should == 1
        relation.first.title.should == 'a title'
      end

      it "where nested with placeholders" do
        Post.create(:title => 'a title', :description => 'same')
        Post.create(:title => 'another title', :description => 'same')
        Post.create(:title => 'a title', :description => 'another')
        relation = Post.where("title = ?", 'a title').where("description = ?", 'another')
        relation.count.should == 1
        relation.first.title.should == 'a title'
      end

      context "where with hash" do
        before do
          Post.create(:title => 'a title', :description => 'same')
          Post.create(:title => 'another title', :description => 'same')
          Post.create(:title => 'a title', :description => 'another')
        end
        it "filtered by one field" do
          relation = Post.where(:title => 'a title')
          relation.count.should == 2
          relation.first.title.should == 'a title'
          relation.first.description.should == 'same'
          relation.last.title.should == 'a title'
          relation.last.description.should == 'another'
        end
        it "filtered by two fields" do
          relation = Post.where(:title => 'a title', :description => 'same')
          relation.count.should == 1
          relation.first.title.should == 'a title'
          relation.first.description.should == 'same'
        end

        it "in list" do
          relation = Post.where(:title => ['a title', 'another title'], :description => 'same')
          relation.count.should == 2
          relation.first.title.should == 'a title'
          relation.first.description.should == 'same'
          relation.last.title.should == 'another title'
          relation.last.description.should == 'same'
        end
      end
    end
  end
end