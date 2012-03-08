require 'graphviz'
require 'set'
require 'call_site_analyzer'

module Rubydeps
  def self.analyze(options = {}, &block_to_analyze)
    dependency_hash, class_location_hash = dependency_hash_for(options, &block_to_analyze)

    if options[:to_file]
      File.open(options[:to_file], 'w') do |f|
        f.write Marshal.dump([dependency_hash, class_location_hash])
      end
    else
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
  end

  def self.dependency_hash_for(options = {}, &block_to_analyze)
    dependency_hash, class_location_hash = if options[:from_file]
                                             File.open(options[:from_file]) { |f| Marshal.load(f) }
                                           else
                                             CallSiteAnalyzer.analyze(&block_to_analyze)
                                           end

    path_filter = options.fetch(:path_filter, /.*/)
    class_name_filter = options.fetch(:class_name_filter, /.*/)
    classes_to_remove = get_classes_to_remove(dependency_hash, class_location_hash, path_filter, class_name_filter)

    while(!classes_to_remove.empty?) do
      klass_to_remove = classes_to_remove.pop
      classes_calling_class_to_remove = dependency_hash[klass_to_remove]
      classes_called_by_class_to_remove = dependency_hash.keys.select do |called_class|
        dependency_hash[called_class].member? klass_to_remove
      end

      #transitive dependencies, hmmm, not sure is a good idea
      #if classes_calling_class_to_remove && !classes_calling_class_to_remove.empty?
      #  classes_called_by_class_to_remove.each do |called_class|
      #    dependency_hash[called_class] |= classes_calling_class_to_remove
      #  end
      #end

      dependency_hash.delete(klass_to_remove)
      classes_called_by_class_to_remove.each do |called_class|
        if dependency_hash[called_class]
          dependency_hash[called_class].delete(klass_to_remove)

          if dependency_hash[called_class].empty?
            dependency_hash.delete(called_class)
          end
        end
      end

    end

    [normalize_class_names(dependency_hash), class_location_hash]
  end

  def self.get_classes_to_remove(dependency_hash, class_location_hash, path_filter, class_name_filter)
    (dependency_hash.keys | dependency_hash.values.flatten).reject do |klass|
      class_name_filter =~ klass &&
      class_location_hash[klass] && !class_location_hash[klass].empty? && class_location_hash[klass].first =~ path_filter
    end
  end

  def self.normalize_class_names(dependency_hash)
    Hash[dependency_hash.map { |k,v| [normalize_class_name(k), v.map{|c| c == k ? nil : normalize_class_name(c)}.compact] }]
  end

  def self.normalize_class_name(klass)
    good_class_name = klass.gsub(/#<(.+):(.+)>/, 'Instance of \1')
    good_class_name.gsub!(/\([^\)]*\)/, "")
    good_class_name.gsub(/0x[\da-fA-F]+/, '(hex number)')
  end
end
