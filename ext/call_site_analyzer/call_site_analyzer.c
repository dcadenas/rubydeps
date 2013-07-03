#include <ruby.h>
#include <vm_core.h>
#include <iseq.h>

#if GET_THREAD
  #define ruby_current_thread ((rb_thread_t *)RTYPEDDATA_DATA(rb_thread_current()))
  #define GET_THREAD2 GET_THREAD
#else
  rb_thread_t *ruby_current_thread;
  rb_thread_t *GET_THREAD2(void)
  {
    ruby_current_thread = ((rb_thread_t *)RTYPEDDATA_DATA(rb_thread_current()));
    return GET_THREAD();
  }
#endif

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
  return rb_class_real(klass);
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

inline static void
add_dependency(VALUE calling_class, VALUE called_class, VALUE called_class_file_path, VALUE is_guess){
  if(called_class == calling_class){
    return;
  }

  const char* called_class_name = rb_class2name(called_class);
  const char* calling_class_name= rb_class2name(calling_class);

  //update depedency_hash
  VALUE dependency_hash = rb_ary_entry(dependency_array, 0);
  VALUE calling_class_array = rb_hash_aref(dependency_hash, rb_str_new2(called_class_name));
  if(NIL_P(calling_class_array)){
    calling_class_array = rb_ary_new();
    rb_hash_aset(dependency_hash, rb_str_new2(called_class_name), calling_class_array);
  }
  rb_ary_push(calling_class_array, rb_str_new2(calling_class_name));

  //update class_location_hash
  if(!NIL_P(called_class_file_path)){
    VALUE class_location_hash = rb_ary_entry(dependency_array, 1);

    VALUE file_path_array = rb_hash_aref(class_location_hash, rb_str_new2(called_class_name));
    if(NIL_P(file_path_array)){
      file_path_array = rb_ary_new();
      rb_hash_aset(class_location_hash, rb_str_new2(called_class_name), file_path_array);
    }

    VALUE last_guess = rb_ary_entry(file_path_array, 1);
    if(last_guess == Qnil || last_guess == Qtrue){
      rb_ary_store(file_path_array, 0, called_class_file_path);
      rb_ary_store(file_path_array, 1, is_guess);
    }
  }
}

//NOTE: this function should be as optimized as possible as it's being called on each ruby method call
static void
event_hook(rb_event_flag_t event, VALUE data, VALUE self, ID mid, VALUE klass){
  rb_control_frame_t* cfp = GET_THREAD2()->cfp;
  VALUE class_of_called_object = class_of_obj_or_class(self);
  VALUE called_class = get_real_class(cfp->iseq->klass);
  VALUE called_class_file_path;

  #ifdef HAVE_TYPE_RB_ISEQ_LOCATION_T
    if (RTEST(cfp->iseq->location.absolute_path))
        called_class_file_path = cfp->iseq->location.absolute_path;
    else
        called_class_file_path = cfp->iseq->location.path;
  #else
    if (RTEST(cfp->iseq->filepath))
        called_class_file_path = cfp->iseq->filepath;
    else
        called_class_file_path = cfp->iseq->filename;
  #endif

  rb_control_frame_t* previous_cfp = callsite_cfp(cfp);
  if(previous_cfp != NULL){
    VALUE calling_class = get_real_class(previous_cfp->iseq->klass);

    if(class_of_called_object != calling_class){
      if(class_of_called_object != called_class){
        //we can't assume that the location of class_of_called_object is the same as the called_class file path, so guess == true
        add_dependency(calling_class, class_of_called_object, called_class_file_path, Qtrue);
      } else {
        add_dependency(calling_class, called_class, called_class_file_path, Qfalse);
      }
    }
  }

  //this dependency represents inheritance/inclusion/extension
  if(class_of_called_object != called_class){
    add_dependency(class_of_called_object, called_class, called_class_file_path, Qfalse);
  }
}

static int uniq_calling_arrays(VALUE called_class, VALUE calling_class_array, VALUE extra){
  rb_funcall(calling_class_array, rb_intern("uniq!"), 0);
  return ST_CONTINUE;
}

static VALUE start(VALUE self){
  dependency_array = rb_ary_new();
  rb_global_variable(&dependency_array);

  VALUE dependency_hash = rb_hash_new();
  rb_ary_push(dependency_array, dependency_hash);

  VALUE class_location_hash = rb_hash_new();
  rb_ary_push(dependency_array, class_location_hash);

  rb_add_event_hook(event_hook, RUBY_EVENT_CALL, Qnil);

  return Qnil;
}

static VALUE result(VALUE self){
  rb_remove_event_hook(event_hook);
  rb_hash_foreach(rb_ary_entry(dependency_array, 0), uniq_calling_arrays, 0);

  return dependency_array;
}

static VALUE rb_cCallSiteAnalyzer;

void Init_call_site_analyzer(){
  rb_cCallSiteAnalyzer = rb_define_module("CallSiteAnalyzer");
  rb_define_singleton_method(rb_cCallSiteAnalyzer, "start", start, 0);
  rb_define_singleton_method(rb_cCallSiteAnalyzer, "result", result, 0);
}
