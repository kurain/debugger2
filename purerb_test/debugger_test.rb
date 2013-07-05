require 'stringio'
require 'minitest/unit'
require 'purerb_debug'

MiniTest::Unit.autorun

module Debugger
  @@debug_debugger = true
end

class TestDebugger < MiniTest::Unit::TestCase
  def test_exact_stack_size
    assert_raises(NoMethodError){ Debugger.exact_stack_size(Thread.current) }
    assert_instance_of(Fixnum, Debugger.class_eval{ exact_stack_size(Thread.current) })
  end

  def test_debug_context_create
    assert_raises(NoMethodError){ Debugger.exact_stack_size(Thread.current) }
    assert_instance_of(DebugContext, Debugger.class_eval{ debug_context_create(Thread.current) })
  end

  def test_thread_context_lookup
    assert_raises(NoMethodError) do
      Debugger.thread_context_lookup(Thread.current,nil,nil,true)
    end
    Debugger.start_
    context, debug_context =
      Debugger.class_eval do
      thread_context_lookup(Thread.current, nil, nil, true)
      end
    assert_instance_of(DebugContext, context)
    assert_instance_of(DebugContext, debug_context)
  end

  def _trace_debug_point(tp)
    current_thread = Thread.current
    Debugger.start_
    Debugger.class_eval do
      context, debug_context = thread_context_lookup(Thread.current, nil, nil, true)
      trace_debug_print(tp, debug_context);
    end
  end

  def test_trace_debug_point
    trace = TracePoint.trace(:line, &method(:_trace_debug_point))
    p "In Test"
    trace.disable
  end

  def test_call_utils
    Debugger.start_
    Debugger.class_eval do
      check_thread_contexts()
      remove_from_locked()
    end
  end

#   def test_register_debug_trace_points
#     skip
#     Debugger.class_eval{attr_accessor :rdebug_threads_tbl}
#     Debugger.rdebug_threads_tbl = {}
#     p Debugger.rdebug_threads_tbl

# #    dummy.register_debug_trace_points

#   end
end
