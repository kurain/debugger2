require 'minitest/unit'
require 'purerb_debug/context'

MiniTest::Unit.autorun

class TestDebugContext < MiniTest::Unit::TestCase
  def setup
    @flags = %w/CTX_FL_SUSPEND
    CTX_FL_SUSPEND
    CTX_FL_TRACING
    CTX_FL_SKIPPED
    CTX_FL_IGNORE
    CTX_FL_DEAD
    CTX_FL_WAS_RUNNING
    CTX_FL_ENABLE_BKPT
    CTX_FL_STEPPED
    CTX_FL_FORCE_MOVE
    CTX_FL_CATCHING/

    @context = DebugContext.new
    @context.thnum = 1;
    @context.last_file = nil;
    @context.last_line = nil;
    @context.flags = 0;
    @context.calced_stack_size = 0

    @context.stop_next  = -1;
    @context.dest_frame = -1;
    @context.stop_line  = -1;
    @context.stop_frame = -1;

    @context.stop_reason = DebugContext::CTX_STOP_NONE;
    @context.thread_id   = nil;
    @context.breakpoint  = nil;
    @context.inspected_frame = nil;
  end

  def test_name
    @flags.each do |name|
      assert_equal name, @context.flag_name(eval("DebugContext::#{name}"))
    end
  end

  def test_set_unset
    @flags.each do |name|
      @context.flag_set(eval("DebugContext::#{name}"))
      assert @context.flag_test(eval("DebugContext::#{name}"))
    end

    @flags.each do |name|
      @context.flag_unset(eval("DebugContext::#{name}"))
      assert !@context.flag_test(eval("DebugContext::#{name}"))
    end
  end
end
