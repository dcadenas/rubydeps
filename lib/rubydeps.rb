require 'graphviz'

module Rubydeps
  def self.for(file_filter = /.*/, result_processor = graphviz_result_processor, &block_to_analyze)
    start(file_filter)
    block_to_analyze.call
    result_processor.call(result)
  ensure
    stop
  end

  def self.graphviz_result_processor
    lambda {|result|
      if result
        g = GraphViz::new( "G", :use => 'dot', :mode => 'major', :rankdir => 'LR', :concentrate => 'true', :fontname => 'Arial')
        result.each do |k,vs|
          unless k.nil?
            n1 = g.add_node(k.to_s)
            if vs.respond_to?(:each)
              vs.keys.each do |v|
                n2 = g.add_node(v.to_s)
                g.add_edge(n1, n2)
              end
            end
          end
        end

        g.output( :png => "rubydeps.png" )
      end
    }
  end

  def self.start(file_filter)
    Thread.current[:class_stack] = []
    Thread.current[:deps] = {}

    set_trace_func proc { |event, file, line, id, binding, classname|
      if (event == 'call' || event == 'return') && file_filter =~ file
        calling_class = Thread.current[:class_stack].last
        if classname.to_s != calling_class
          dependencies_of_calling_class = Thread.current[:deps][calling_class] ||= {}
          dependencies_of_calling_class[classname.to_s] ||= 0
          dependencies_of_calling_class[classname.to_s] += 1

          Thread.current[:class_stack].push(classname.to_s) if event == 'call'
        end

        Thread.current[:class_stack].pop if event == 'return'
      end
    }
  end

  def self.result
    Thread.current[:deps].clone if Thread.current[:deps]
  end

  def self.stop
    set_trace_func(nil)
    Thread.current[:deps].clear if Thread.current[:deps]
    Thread.current[:class_stack].clear if Thread.current[:class_stack]
  end
end

