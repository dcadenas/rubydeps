require 'file_test_helper'

module GrandparentModule
  def class_method
  end
end

class Grandparent
  extend GrandparentModule

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
    dependencies = ::Rubydeps.dependency_hash_for do
      class IHaveAClassLevelDependency
        Son.class_method
      end
    end

    dependencies.should == {"Parent"=>["Son"]}
  end

  it "should create a dot file" do
    with_files do
      dependencies = ::Rubydeps.create_dot_for do
        class IHaveAClassLevelDependency
          Son.class_method
        end
      end

      File.read("rubydeps.dot").should match("digraph G")
    end
  end

  it "should be idempotent" do
    ::Rubydeps.dependency_hash_for do
      class IHaveAClassLevelDependency
        Son.class_method
      end
    end

    dependencies = ::Rubydeps.dependency_hash_for do
      class IHaveAClassLevelDependency
        Son.class_method
      end
    end

    dependencies.should == {"Parent"=>["Son"]}
  end

  it "should show the dependencies between the classes inside the block" do
    dependencies = ::Rubydeps.dependency_hash_for do
      Son.class_method
      Son.new.instance_method
    end

    dependencies.keys.should =~ ["Parent", "Grandparent"]
    dependencies["Parent"].should == ["Son"]
    dependencies["Grandparent"].should =~ ["Son", "Parent"]
  end

  sample_dir_structure = {'path1/class_a.rb' => <<-CLASSA,
                             require './path1/class_b'
                             require './path2/class_c'
                             class A
                               def depend_on_b_and_c
                                 B.new.b
                                 C.new.c
                               end
                             end
                           CLASSA
                           'path1/class_b.rb' => 'class B; def b; end end',
                           'path2/class_c.rb' => 'class C; def c; end end'}

  it "should not filter classes when no filter is specified" do
    with_files(sample_dir_structure) do
      load './path1/class_a.rb'

      dependencies = ::Rubydeps.dependency_hash_for do
        A.new.depend_on_b_and_c
      end

      dependencies.should == {"B"=>["A"], "C"=>["A"]}
    end
  end

  it "should filter classes when a path filter is specified" do
    with_files(sample_dir_structure) do
      load './path1/class_a.rb'

      dependencies = ::Rubydeps.dependency_hash_for(:path_filter => /path1/) do
        A.new.depend_on_b_and_c
      end

      dependencies.should == {"B"=>["A"]}
    end
  end

  it "should filter classes when a class name filter is specified" do
    with_files(sample_dir_structure) do
      load './path1/class_a.rb'

      dependencies = ::Rubydeps.dependency_hash_for(:class_name_filter => /C|A/) do
        A.new.depend_on_b_and_c
      end

      dependencies.should == {"C"=>["A"]}
    end
  end
end
