[![Build Status](https://secure.travis-ci.org/dcadenas/rubydeps.png?branch=master)](http://travis-ci.org/dcadenas/rubydeps)
rubydeps
========

A tool to create class dependency graphs from test suites

Sample output
-------------

This is the result of running rubydeps on the [Rake](https://github.com/jimweirich/rake) tests:

```bash
rubydeps testunit --class_name_filter='^Rake'
```

![Rake dependencies](https://github.com/dcadenas/rubydeps/raw/master/rake-deps.png)


Command line usage
------------------


Rubydeps will run your test suite to record the call graph of your project and use it to create a dot graph.

First of all, be sure to step into the root directory of your project, rubydeps searches for ./spec or ./test dirs from there.
For example, if we want to graph the Rails activemodel dependency graph we'd cd to rails/activemodel and from there we'd write:

```bash
rubydeps testunit #to run Test::Unit tests
```    

or

```bash
rubydeps rspec #to run RSpec tests
```

or

```bash
rubydeps rspec2 #to run RSpec 2 tests
```

This will output a rubydeps.dot. You can convert the dot file to any image format you like using the dot utility that comes with the graphviz installation e.g.:

```bash
dot -Tsvg rubydeps.dot > rubydeps.svg
```

Notice that sometimes you may have missing dependencies as we graph the dependencies exercised by your tests so it's a quick bird's eye view to check your project coverage.

### Command line options

The `--path_filter` option specifies a regexp that matches the path of the files you are interested in analyzing. For example you could have filters like `'project_name/app|project_name/lib'` to analyze only code that is located in the `app` and `lib` dirs or as an alternative you could just exclude some directory you are not interested using a negative regexp like `'project_name(?!.*test)'`

The `--class_name_filter` option is similar to the `--path_filter` options except that the regexp is matched against the class names (i.e. graph node names).

The `--to_file` option dumps the dependency graph data to a file so you can do filtering later, it does not create a dot file.

The `--from_file` option is only available when you don't specify a test command. Its argument is the file dumped through `--to_file` in a previous run. When you use this option the tests (or block) are not ran, the dependency graph is loaded directly from the file. This is useful to avoid rerunning code that didn't change just for the purpose of filtering with different combinations e.g.:

```bash
rubydeps rspec2 --to_file='dependencies.dump'
rubydeps --from_file='dependencies.dump' --path_filter='app/models'
rubydeps --from_file='dependencies.dump' --path_filter='app/models|app/controllers'
```

Library usage
-------------

Just require rubydeps and pass a block to analyze to the `analyze` method.

```ruby
require 'rubydeps'

Rubydeps.analyze(:path_filter => path_filter_regexp, :class_name_filter => class_name_filter_regexp, :to_file => "dependencies.dump") do
    # your code goes here
end
```

Installation
------------

```bash
gem install rubydeps
```

Rubydeps now only supports ruby 1.9. If you need 1.8.x support then:

```bash
gem install rubydeps -v0.2.0
```

Notice that in 0.2.0 you should use dot_for instead of analyze.

Dependencies
------------

* rcov (only for version 0.2.0)
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

Copyright (c) 2012 Daniel Cadenas. See LICENSE for details.

Development sponsored by [Cubox](http://www.cuboxlabs.com)
