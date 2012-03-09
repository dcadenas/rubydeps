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

  def instance_method_that_calls_parent_class_method
    Parent.class_method
  end

  def instance_method_calling_another_instance_method(second_receiver)
    second_receiver.instance_method
  end

  def instance_method
    Parent.class_method
    Grandparent.class_method
  end
end

describe "Rubydeps" do
  include FileTestHelper

  it "should show the class level dependencies" do
    dependencies, _ = ::Rubydeps.dependency_hash_for do
      class IHaveAClassLevelDependency
        Son.class_method
      end
    end

    dependencies.should == {"Parent"=>["Son"]}
  end

  it "should create a dot file" do
    with_files do
      ::Rubydeps.analyze do
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

    dependencies, _ = ::Rubydeps.dependency_hash_for do
      class IHaveAClassLevelDependency
        Son.class_method
      end
    end

    dependencies.should == {"Parent"=>["Son"]}
  end

  it "should show the dependency from an object singleton method" do
    dependencies, _ = ::Rubydeps.dependency_hash_for do
      s = Son.new
      def s.attached_method
        Grandparent.class_method
      end
      s.attached_method
    end

    dependencies.keys.should == ["Grandparent", "GrandparentModule"]
    dependencies["Grandparent"].should == ["Son"]
    dependencies["GrandparentModule"].should == ["Grandparent"]
  end

  it "should show the dependencies between the classes inside the block" do
    dependencies, _ = ::Rubydeps.dependency_hash_for do
      Son.new.instance_method
    end

    dependencies.keys.should =~ ["Parent", "Grandparent", "GrandparentModule"]
    dependencies["Parent"].should == ["Son"]
    dependencies["Grandparent"].should =~ ["Son", "Parent"]
    dependencies["GrandparentModule"].should == ["Grandparent"]
  end

  it "should create correct dependencies for 2 instance methods called in a row" do
    dependencies, _ = ::Rubydeps.dependency_hash_for do
      Son.new.instance_method_calling_another_instance_method(Parent.new)
    end

    dependencies.should == {"Parent"=>["Son"]}
  end

  context "with a dumped dependencies file" do
    sample_dir_structure = {'path1/class_a.rb' => <<-CLASSA,
                               require '#{File.dirname(__FILE__)}/../lib/rubydeps'

                               require './path1/class_b'
                               require './path2/class_c'
                               class A
                                 def depend_on_b_and_c
                                   B.new.b
                                   C.new.c
                                 end
                               end

                               Rubydeps.start
                               A.new.depend_on_b_and_c
                             CLASSA
                             'path1/class_b.rb' => 'class B; def b; end end',
                             'path2/class_c.rb' => 'class C; def c; end end'}

    it "should be a correct test file" do
      with_files(sample_dir_structure) do
        status = system("ruby -I#{File.dirname(__FILE__)}/../lib ./path1/class_a.rb")
        status.should be_true
      end
    end

    it "should not filter classes when no filter is specified" do
      with_files(sample_dir_structure) do
        system("ruby -I#{File.dirname(__FILE__)}/../lib ./path1/class_a.rb")

        dependencies, _ = ::Rubydeps.dependency_hash_for(:from_file => 'rubydeps.dump')
        dependencies.should == {"B"=>["A"], "C"=>["A"]}
      end
    end

    it "should filter classes when a path filter is specified" do
      with_files(sample_dir_structure) do
        system("ruby -I#{File.dirname(__FILE__)}/../lib ./path1/class_a.rb")

        dependencies, _ = ::Rubydeps.dependency_hash_for(:from_file => 'rubydeps.dump', :path_filter => /path1/)
        dependencies.should == {"B"=>["A"]}
      end
    end

    it "should filter classes when a class name filter is specified" do
      with_files(sample_dir_structure) do
        system("ruby -I#{File.dirname(__FILE__)}/../lib ./path1/class_a.rb")

        dependencies, _ = ::Rubydeps.dependency_hash_for(:from_file => 'rubydeps.dump', :class_name_filter => /C|A/)
        dependencies.should == {"C"=>["A"]}
      end
    end
  end
end
