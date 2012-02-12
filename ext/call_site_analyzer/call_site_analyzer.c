#include <ruby.h>
#include <vm_core.h>
#include <iseq.h>

inline static rb_control_frame_t*
callsite_cfp(rb_control_frame_t* cfp){
  cfp = RUBY_VM_PREVIOUS_CONTROL_FRAME(cfp);
  if (cfp->iseq != 0 && cfp->pc != 0) {
    return cfp;
  }
  else if (cfp->block_iseq) {
    while (!cfp->iseq) cfp = RUBY_VM_PREVIOUS_CONTROL_FRAME(cfp);
    return cfp;
  }

  return NULL;
}

inline static VALUE
get_real_class(VALUE klass){
  if (FL_TEST(klass, FL_SINGLETON)) {
    VALUE v = rb_iv_get(klass, "__attached__");

    switch (TYPE(v)) {
      case T_CLASS: case T_MODULE:
        return v;
      default:
        return rb_class_real(klass);
    }
  }
  return klass;
}

inline static VALUE
class_of_obj_or_class(VALUE obj_or_class){
  switch(TYPE(obj_or_class)){
    case T_CLASS: case T_MODULE:
      return obj_or_class;
    default:
      return rb_obj_class(obj_or_class);
  }
}

static VALUE dependency_array;

//NOTE: this function should be as optimized as possible as it's being called on each ruby method call
static void
event_hook(rb_event_flag_t event, VALUE data, VALUE self, ID mid, VALUE klass){
  rb_control_frame_t* cfp = GET_THREAD()->cfp;

  rb_control_frame_t* previous_cfp = callsite_cfp(cfp);
  if(previous_cfp == NULL){
    return;
  }

  klass = class_of_obj_or_class(self);

  rb_iseq_t* previous_iseq = previous_cfp->iseq;
  VALUE prevklass = get_real_class(previous_iseq->klass);

  //we return if there's a dependency with the same class or with Object
  if(klass == prevklass){
    return;
  }

  const char* class_name = rb_class2name(klass);
  const char* prevklass_name = rb_class2name(prevklass);

  if(TYPE(klass) == T_FALSE || TYPE(prevklass) == T_FALSE){
    return;
  }

  //update depedency_hash
  VALUE dependency_hash = rb_ary_entry(dependency_array, 0);
  VALUE calling_class_array = rb_hash_aref(dependency_hash, rb_str_new2(class_name));
  if(NIL_P(calling_class_array)){
    calling_class_array = rb_ary_new();
    rb_hash_aset(dependency_hash, rb_str_new2(class_name), calling_class_array);
  }
  rb_ary_push(calling_class_array, rb_str_new2(prevklass_name));

  //update class_location_hash
  VALUE filepath = cfp->iseq->filepath;
  if(!NIL_P(filepath)){
    VALUE class_location_hash = rb_ary_entry(dependency_array, 1);
    rb_hash_aset(class_location_hash, rb_str_new2(class_name), filepath);
    rb_hash_aset(class_location_hash, rb_str_new2(prevklass_name), previous_iseq->filepath);
  }
}

static int uniq_calling_arrays(VALUE called_class, VALUE calling_class_array, VALUE extra){
  rb_funcall(calling_class_array, rb_intern("uniq!"), 0);
  return ST_CONTINUE;
}

static VALUE analyze(VALUE self){
  if(rb_block_given_p()) {
    dependency_array = rb_ary_new();
    rb_global_variable(&dependency_array);

    VALUE dependency_hash = rb_hash_new();
    rb_ary_push(dependency_array, dependency_hash);

    VALUE class_location_hash = rb_hash_new();
    rb_ary_push(dependency_array, class_location_hash);

    rb_add_event_hook(event_hook, RUBY_EVENT_CALL, Qnil);
    rb_yield(Qnil);
    rb_remove_event_hook(event_hook);

    rb_hash_foreach(rb_ary_entry(dependency_array, 0), uniq_calling_arrays, 0);
  } else {
    rb_raise(rb_eArgError, "a block is required");
  }

  return dependency_array;
}

static VALUE rb_cCallSiteAnalyzer;

void Init_call_site_analyzer(){
  rb_cCallSiteAnalyzer = rb_define_module("CallSiteAnalyzer");
  rb_define_singleton_method(rb_cCallSiteAnalyzer, "analyze", analyze, 0);
}
