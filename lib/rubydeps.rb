require 'graphviz'
require 'set'
require 'call_site_analyzer'

module Rubydeps
  def self.create_dot_for(options = {}, &block_to_analyze)
    dependency_hash = dependency_hash_for(options, &block_to_analyze)

    if dependency_hash
      g = GraphViz::new( "G", :use => 'dot', :mode => 'major', :rankdir => 'LR', :concentrate => 'true', :fontname => 'Arial')
      dependency_hash.each do |k,vs|
        if !k.empty? && !vs.empty?
          n1 = g.add_nodes(k.to_s)
          if vs.respond_to?(:each)
            vs.each do |v|
              unless v.empty?
                n2 = g.add_nodes(v.to_s)
                g.add_edges(n2, n1)
              end
            end
          end
        end
      end

      g.output( :dot => "rubydeps.dot" )
    end
  end

  def self.dependency_hash_for(options = {}, &block_to_analyze)
    dependency_hash, class_location_hash = CallSiteAnalyzer.analyze(&block_to_analyze)

    path_filter = options.fetch(:path_filter, /.*/)
    apply_path_filter(dependency_hash, class_location_hash, path_filter)

    class_name_filter = options.fetch(:class_name_filter, /.*/)
    apply_class_name_filter(dependency_hash, class_name_filter)

    normalize_class_names(dependency_hash)
  end

  def self.apply_path_filter(dependency_hash, class_location_hash, path_filter_regexp)
    return if path_filter_regexp == /.*/

    dependency_hash.each do |called_class, calling_classes|
      if class_location_hash[called_class] && path_filter_regexp =~ class_location_hash[called_class]
        calling_classes.select! do |calling_class|
          path_filter_regexp =~ class_location_hash[calling_class] if class_location_hash[calling_class]
        end
      else
        dependency_hash.delete(called_class)
      end
    end
  end

  def self.apply_class_name_filter(dependency_hash, class_name_filter_regexp)
    return if class_name_filter_regexp == /.*/

    dependency_hash.each do |called_class, calling_classes|
      if class_name_filter_regexp =~ called_class
        calling_classes.select! do |calling_class|
          class_name_filter_regexp =~ calling_class
        end
      else
        dependency_hash.delete(called_class)
      end
    end
  end

  def self.normalize_class_names(dependency_hash)
    Hash[dependency_hash.map { |k,v| [normalize_class_name(k), v.map{|c| normalize_class_name(c)}] }]
  end

  def self.normalize_class_name(klass)
    good_class_name = klass.gsub(/#<Class:(.+)>/, '\1')
    good_class_name.gsub!(/\([^\)]*\)/, "")
    good_class_name.gsub(/0x[\da-fA-F]+/, '(hex number)')
  end
end
