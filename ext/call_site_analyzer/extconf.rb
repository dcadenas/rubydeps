require 'mkmf'
require "ruby_core_source"

#comment this line if not debugging
$CFLAGS='-ggdb -Wall -O0 -pipe'

hdrs = proc { have_header("vm_core.h") and have_header("iseq.h") }

if !Ruby_core_source::create_makefile_with_core(hdrs, "call_site_analyzer")
  STDERR.print("Makefile creation failed\n")
end
