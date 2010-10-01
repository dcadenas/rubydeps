require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'filetesthelper'

class Grandparent
  def self.class_method
  end

  def instance_method
  end
end

class Parent
  def self.class_method
    Grandparent.class_method
  end

  def instance_method
  end
end

class Son
  def self.class_method
    parent = Parent.new
    parent.instance_method
    parent.instance_method
    class_method2
    class_method2
  end

  def self.class_method2
  end

  def instance_method
    Parent.class_method
    Grandparent.class_method
  end
end

describe "Rubydeps" do
  include FileTestHelper
  it "should show the class level dependencies" do
    dependencies = Rubydeps.hash_for do
      class IHaveAClassLevelDependency
        Son.class_method
      end
    end

    dependencies.should == {"Parent"=>["Son"]}
  end

  it "should create a dot file" do
    with_files do
      dependencies = Rubydeps.dot_for do
        class IHaveAClassLevelDependency
          Son.class_method
        end
      end

      File.read("rubydeps.dot").should match("digraph G")
    end
  end

  it "should be idempotent" do
    Rubydeps.hash_for do
      class IHaveAClassLevelDependency
        Son.class_method
      end
    end

    dependencies = Rubydeps.hash_for do
      class IHaveAClassLevelDependency
        Son.class_method
      end
    end

    dependencies.should == {"Parent"=>["Son"]}
  end

  it "should show the dependencies between the classes inside the block" do
    dependencies = Rubydeps.hash_for do
      Son.class_method
      Son.new.instance_method
    end

    dependencies.should == {"Parent"=>["Son"], "Grandparent"=>["Parent", "Son"]}
  end
end
