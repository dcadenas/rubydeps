[![Build Status](https://secure.travis-ci.org/dcadenas/rubydeps.png?branch=master)](http://travis-ci.org/dcadenas/rubydeps)
[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/dcadenas/rubydeps)
[![endorse](http://api.coderwall.com/dcadenas/endorsecount.png)](http://coderwall.com/dcadenas)

rubydeps
========

A tool to create class dependency graphs from test suites.

I think this is more useful than static analysis of the code base because of the high dynamic aspects of the language. 

Sample output
-------------

This is the result of running rubydeps on the [Rake](https://github.com/jimweirich/rake) tests after setting up its test helper with `Rubydeps.start`:

```bash
rubydeps --class_name_filter='^Rake'
```

![Rake dependencies](https://github.com/dcadenas/rubydeps/raw/master/rake-deps.png)

Usage
---------------

Rubydeps will run your test suite to record the call graph of your project and use it to create a [Graphviz](http://www.graphviz.org) dot graph.

1. Add Rubydeps to your `Gemfile` and `bundle install`:

        gem 'rubydeps', :group => :test

2. Launch Rubydeps by inserting this line in your `test/test_helper.rb` (*or `spec_helper.rb`, cucumber `env.rb`, or whatever
   your preferred test framework uses*):

        Rubydeps.start

    Notice that this will slow down your tests so consider adding a conditional bound to some ENV variable or just remove the line when you are done.

3. Run your tests, a file named `rubydeps.dump` will be created in the project root.

4. The next step is reading the dump file to generate the [Graphviz](http://www.graphviz.org) dot graph `rubydeps.dot` with any filter you specify.

    ```bash
    rubydeps --path_filter='app/models'
    ```

5. Now you are in [Graphviz](http://www.graphviz.org) realm. You can convert the dot file to any image format with your prefered orientations and layouts with the dot utility that comes with the [Graphviz](http://www.graphviz.org) installation e.g.:

    ```bash
    dot -Tsvg rubydeps.dot > rubydeps.svg
    ```

    Keep in mind that sometimes you may have missing dependencies as we graph the dependencies exercised by your tests so you can use it as a quick bird's eye view of your project test coverage.

### Command line options

* The `--path_filter` option specifies a regexp that matches the path of the files you are interested in analyzing. For example you could have filters like `'project_name/app|project_name/lib'` to analyze only code that is located in the `app` and `lib` dirs or as an alternative you could just exclude some directory you are not interested using a negative regexp like `'project_name(?!.*test)'`

* The `--class_name_filter` option is similar to the `--path_filter` options except that the regexp is matched against the class names (i.e. graph node names).

* The `--from_file` option is used to specify the dump file generated after the test (or block) run so you can try different filters without needing to rerun the tests. e.g.:

    ```bash
    rubydeps --from_file='rubydeps.dump' --path_filter='app/models'
    rubydeps --from_file='rubydeps.dump' --path_filter='app/models|app/controllers'
    ```

  If you didn't rename the file you can skip this option as it will use the default `rubydeps.dump` 

Library usage
-------------

Just require rubydeps and pass a block to analyze to the `analyze` method.

```ruby
require 'rubydeps'

Rubydeps.analyze(:path_filter => path_filter_regexp, :class_name_filter => class_name_filter_regexp, :to_file => "rubydeps.dump") do
    # your code goes here
end
```

Installation
------------

```bash
gem install rubydeps
```

Rubydeps now only supports ruby >= 1.9.2. If you need 1.8.x support then:

```bash
gem install rubydeps -v0.2.0
```

Notice that in 0.2.0 you should use `dot_for` instead of `analyze` and the dump functionality is missing.

Dependencies
------------

* graphviz
* ruby-graphviz gem
* rcov gem (only for version 0.2.0)

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

Development sponsored by [Neo](http://neo.com)
