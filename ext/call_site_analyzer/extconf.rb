require 'mkmf'
require "debugger/ruby_core_source"

#comment this line if not debugging
#$CFLAGS='-ggdb -Wall -O0 -pipe'

hdrs = proc { 
  have_type("rb_iseq_location_t", "vm_core.h")

  have_header("vm_core.h") and have_header("iseq.h")
}

if !Debugger::RubyCoreSource::create_makefile_with_core(hdrs, "call_site_analyzer")
  STDERR.print("Makefile creation failed\n")
end
