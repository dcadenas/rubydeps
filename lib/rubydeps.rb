require 'rcov'
require 'graphviz'
require 'set'

module Rubydeps
  def self.dot_for(path_filter = /.*/, &block_to_analyze)
    dependencies_hash = hash_for(path_filter, &block_to_analyze)

    if dependencies_hash
      g = GraphViz::new( "G", :use => 'dot', :mode => 'major', :rankdir => 'LR', :concentrate => 'true', :fontname => 'Arial')
      dependencies_hash.each do |k,vs|
        if !k.empty? && !vs.empty?
          n1 = g.add_node(k.to_s)
          if vs.respond_to?(:each)
            vs.each do |v|
              unless v.empty?
                n2 = g.add_node(v.to_s)
                g.add_edge(n2, n1)
              end
            end
          end
        end
      end

      g.output( :dot => "rubydeps.dot" )
    end
  end

  def self.hash_for(path_filter = /.*/, &block_to_analyze)
    analyzer = Rcov::CallSiteAnalyzer.new
    analyzer.run_hooked do
      block_to_analyze.call
    end

    #TODO: refactor this, needs method extractions, etc

    filtered_classes = Set.new

    dependencies_hash = {}
    analyzer.analyzed_classes.each do |c|
      called_class_name = normalize_class_name(c)
        dependencies_hash[called_class_name] = {}
        analyzer.methods_for_class(c).each do |m|
          called_class_method = "#{c}##{m}"
          if path_filter =~ File.expand_path(analyzer.defsite(called_class_method).file)
            filtered_classes << called_class_name
            analyzer.callsites(called_class_method).each do |key, _|
              calling_class = key.calling_class
              calling_class_name = normalize_class_name(calling_class.to_s)

              dependencies_hash[called_class_name][calling_class_name] ||= 1
            end
        end
      end
    end

    clean_hash(dependencies_hash, filtered_classes)
  end

private
  def self.clean_hash(hash, filtered_classes)
    #TODO: refactor
    cleaned_hash = {}
    hash.each do |called_class_name, calling_class_names_hash|
      if interesting_class_name(called_class_name) && !hash[called_class_name].empty? && filtered_classes.member?(called_class_name)
        cleaned_hash[called_class_name] = calling_class_names_hash.keys.compact.select{|c| interesting_class_name(c) && c != called_class_name && filtered_classes.member?(c) }
        cleaned_hash.delete(called_class_name) if cleaned_hash[called_class_name].empty?
      end
    end

    cleaned_hash
  end

  def self.normalize_class_name(klass)
    good_class_name = klass.gsub(/#<Class:(.+)>/, '\1')
    good_class_name.gsub(/\([^\)]*\)/, "")
  end

  def self.interesting_class_name(class_name)
    !class_name.empty? && class_name != "Rcov::CallSiteAnalyzer" && class_name != "Rcov::DifferentialAnalyzer"
  end
end


