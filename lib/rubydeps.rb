require 'graphviz'
require 'call_site_analyzer'

module Rubydeps
  def self.start(install_at_exit = true)
    CallSiteAnalyzer.start
    at_exit { self.do_at_exit } if install_at_exit
  end

  def self.analyze(options = {}, &block_to_analyze)
    dependency_hash, class_location_hash = dependency_hash_for(options, &block_to_analyze)
    create_output_file(dependency_hash, class_location_hash, options)
  end

  def self.dependency_hash_for(options = {}, &block_to_analyze)
    dependency_hash, class_location_hash = calculate_or_load_dependencies(options, &block_to_analyze)

    apply_filters(dependency_hash, class_location_hash, options)

    [normalize_class_names(dependency_hash), class_location_hash]
  end

  def self.create_output_file(dependency_hash, class_location_hash, options)
    if options[:to_file]
      File.open(options[:to_file], 'wb') do |f|
        f.write Marshal.dump([dependency_hash, class_location_hash])
      end
    else
      create_dot_file(dependency_hash)
    end
  end

  def self.do_at_exit
    # Store the exit status of the test run since it goes away after calling the at_exit proc...
    exit_status = if $!
      $!.is_a?(SystemExit) ? $!.status : 1
    end

    dependency_hash, class_location_hash = CallSiteAnalyzer.result
    create_output_file(dependency_hash, class_location_hash, :to_file => Rubydeps.default_dump_name, :class_name_filter => /.*/, :path_filter => /.*/)

    exit exit_status if exit_status
  end

  def self.calculate_or_load_dependencies(options, &block_to_analyze)
    if options[:from_file]
      Marshal.load(File.binread(options[:from_file]))
    else
      begin
        self.start(false)
        block_to_analyze.call()
      ensure
       return CallSiteAnalyzer.result
      end
    end
  end

  def self.apply_filters(dependency_hash, class_location_hash, options)
    path_filter = options.fetch(:path_filter, /.*/)
    class_name_filter = options.fetch(:class_name_filter, /.*/)
    classes_to_remove = get_classes_to_remove(dependency_hash, class_location_hash, path_filter, class_name_filter)

    while(!classes_to_remove.empty?) do
      klass_to_remove = classes_to_remove.pop
      classes_calling_class_to_remove = dependency_hash[klass_to_remove]
      classes_called_by_class_to_remove = dependency_hash.keys.select do |called_class|
        dependency_hash[called_class].member? klass_to_remove
      end

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
  end

  def self.normalize_class_name(klass)
    good_class_name = klass.gsub(/#<(.+):(.+)>/, 'Instance of \1')
    good_class_name.gsub!(/\([^\)]*\)/, "")
    good_class_name.gsub(/0x[\da-fA-F]+/, '(hex number)')
  end

  def self.create_dot_file(dependency_hash)
    return unless dependency_hash

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

  def self.get_classes_to_remove(dependency_hash, class_location_hash, path_filter, class_name_filter)
    (dependency_hash.keys | dependency_hash.values.flatten).reject do |klass|
      class_name_filter =~ klass &&
      class_location_hash[klass] && !class_location_hash[klass].empty? && class_location_hash[klass].first =~ path_filter
    end
  end

  def self.normalize_class_names(dependency_hash)
    Hash[dependency_hash.map { |k,v| [normalize_class_name(k), v.map{|c| c == k ? nil : normalize_class_name(c)}.compact] }]
  end

  def self.default_dump_name
    "rubydeps.dump"
  end
end
