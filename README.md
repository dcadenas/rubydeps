rubydeps
========

A tool to create class dependency graphs from test suites

Command line usage
------------------


Rubydeps will run your test suite to record the call graph of your project and use it to create a dot graph.

First of all, be sure to step into the root directory of your project, rubydeps searches for ./spec or ./test dirs from there.
For example, if we want to graph the Rails activemodel dependency graph we'd cd to rails/activemodel and from there we'd write:

    rubydeps testunit #to run Test::Unit tests
or
    rubydeps rspec #to run RSpec tests
or
    rubydeps rspec2 #to run RSpec 2 tests

This will output a rubydeps.dot. You can convert the dot file to any image format you like using the dot utility that comes with the graphviz installation e.g.:

    dot -Tsvg rubydeps.dot > rubydeps.svg

### Command line options

The --path-filter option specifies a regexp that matches the path of the files you are interested in analyzing. For example you could have filters like 'project_name/app|project_name/lib' to analyze only code that is located in the 'app' and 'lib' dirs or as an alternative you could just exclude some directory you are not interested using a negative regexp like 'project_name(?!.*test)'

The --class_name_filter option is similar to the --path_filter options except that the regexp is matched against the class names (i.e. graph node names).

Library usage
-------------

Just require rubydeps and pass a block to analyze to the dot_for method.

    require 'rubydeps'

    Rubydeps.dot_for(:path_filter => path_filter_regexp, :class_name_filter) do
      //your code goes here
    end

Sample output
-------------

This is the result of running rubydeps on the [Mechanize](http://github.com/tenderlove/mechanize) tests:

![Mechanize dependencies](https://github.com/dcadenas/rubydeps/raw/master/mechanize-deps.png)

Notice that sometimes you may have missing dependencies as we graph the dependencies exercised by your tests so it's a quick bird's eye view to check your project coverage.

Installation
------------

    gem install rubydeps

Dependencies
------------

* rcov
* graphviz
* ruby-graphviz

Note on Patches/Pull Requests
-----------------------------

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

Copyright
---------

Copyright (c) 2010 Daniel Cadenas. See LICENSE for details.

Development sponsored by [Cubox](http://www.cuboxsa.com)
