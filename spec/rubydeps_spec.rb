require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

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
  it "should show the class level dependencies" do
    dependencies = Rubydeps.for(/.*/, lambda{|result| result}) do
      class IHaveAClassLevelDependency
        Son.class_method
      end
    end

    dependencies.should == {
      nil=>{"Son"=>3, "Rubydeps"=>3},
      "Son"=>{"Parent"=>2}
    }
  end

  it "should be idempotent" do
    Rubydeps.for(/.*/, lambda{|result| result}) do
      class IHaveAClassLevelDependency
        Son.class_method
      end
    end

    dependencies = Rubydeps.for(/.*/, lambda{|result| result}) do
      class IHaveAClassLevelDependency
        Son.class_method
      end
    end

    dependencies.should == {
      nil=>{"Son"=>3, "Rubydeps"=>3},
      "Son"=>{"Parent"=>2}
    }
  end

  it "should show the dependencies between the classes inside the block" do
    dependencies = Rubydeps.for(/.*/, lambda{|result| result}) do
      Son.class_method
      Son.new.instance_method
    end

    dependencies.should == {
      nil=>{"Son"=>4, "Rubydeps"=>3},
      "Son"=>{"Grandparent"=>1, "Parent"=>3},
      "Parent"=>{"Grandparent"=>1}
    }
  end
end
