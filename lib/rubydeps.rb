require 'graphviz'
require 'set'
require 'rcovrt'
require 'rcov'

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

    dependency_hash = create_dependency_hash(analyzer, path_filter)
    clean_hash(dependency_hash)
  end

private
  def self.path_filtered_site?(code_site, path_filter)
    code_site && path_filter =~ File.expand_path(code_site.file)
  end

  #we build a hash structured in this way: {"called_class_name1" => ["calling_class_name1", "calling_class_name2"], "called_class_name2" => ...}
  def self.create_dependency_hash(analyzer, path_filter)
    dependency_hash = {}
    analyzer.analyzed_classes.each do |c|
      called_class_name = normalize_class_name(c)
      analyzer.methods_for_class(c).each do |m|
        called_class_method = "#{c}##{m}"
        def_site = analyzer.defsite(called_class_method)
        if path_filtered_site?(def_site, path_filter)
          calling_class_names = []
          analyzer.callsites(called_class_method).each do |call_site, _|
            if path_filtered_site?(call_site, path_filter)
              calling_class = call_site.calling_class
              calling_class_name = normalize_class_name(calling_class.to_s)
              calling_class_names << calling_class_name
            end
          end
          dependency_hash[called_class_name] = calling_class_names.compact.uniq
        end
      end
    end

    dependency_hash
  end

  def self.clean_hash(dependency_hash)
    cleaned_hash = {}
    dependency_hash.each do |called_class_name, calling_class_names|
      if interesting_class_name(called_class_name) && !dependency_hash[called_class_name].empty?
        cleaned_hash[called_class_name] = calling_class_names.select{|c| interesting_class_name(c) && c != called_class_name }
        cleaned_hash.delete(called_class_name) if cleaned_hash[called_class_name].empty?
      end
    end

    cleaned_hash
  end

  def self.interesting_class_name(class_name)
    !class_name.empty? && class_name != "Rcov::CallSiteAnalyzer" && class_name != "Rcov::DifferentialAnalyzer"
  end

  def self.normalize_class_name(klass)
    good_class_name = klass.gsub(/#<Class:(.+)>/, '\1')
    good_class_name.gsub(/\([^\)]*\)/, "")
  end
end
