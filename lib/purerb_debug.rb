require 'purerb_debug/context.rb'
require 'debug_inspector'

module Debugger
  VERSION = 0.1
  @@debug_debugger = false
  @@debug_debugger_stack_size = false

  @@last_context = nil
  @@last_thread  = nil

  @@tracing      = false
  @@locker       = nil
  @@tracepoints  = nil

  @@last_debug_context = nil;

  @@rdebug_breakpoints = nil;
  @@rdebug_catchpoints = nil;
  @@rdebug_threads_tbl = nil;

  @@start_count = 0
  @@thnum_max   = 0

  @@last_check  = 0
  @@hook_count  = 0

  @@locked_threads = [];

class << self
  private
  def exact_stack_size(thread)
    locs = thread.backtrace_locations
    stack_size = locs.size
    if @@debug_debugger_stack_size && @@debug_debugger
      printf $stderr, "[debug:stacksize] %d\n", stack_size
      p locs
    end
    return stack_size
  end

  def debug_context_create(thread)
    context = DebugContext.new
    context.thnum = (@@thnum_max += 1);
    context.last_file = nil;
    context.last_line = nil;
    context.flags = 0;
    context.calced_stack_size = exact_stack_size(thread);

    context.stop_next  = -1;
    context.dest_frame = -1;
    context.stop_line  = -1;
    context.stop_frame = -1;

    context.stop_reason = DebugContext::CTX_STOP_NONE;
    context.thread_id   = thread.object_id;
    context.breakpoint  = nil;
    context.inspected_frame = nil;

    if (thread.class == DebugThread)
        context.flag_set(DebugContext::CTX_FL_IGNORE);
    end
    return context
  end

  def thread_context_lookup(thread, context, debug_context, create)
    l_debug_context = nil

    if !@@last_context.nil? && @@last_thread == thread
      return [@@last_context, @@last_debug_context]
    end

    if !(context = @@rdebug_threads_tbl[thread]) || !context
      if create
        context = debug_context_create(thread)
        @@rdebug_threads_tbl[thread] = context
      else
        return [nil, nil]
      end
    end

    debug_context = context
    @@last_thread = thread
    @@last_context  = context
    @@last_debug_context  = context
    return [context, debug_context]
  end

  def trace_debug_print(trace_point, debug_context)
    if @@debug_debugger == true
      path  = trace_point.path
      line  = trace_point.lineno
      event = trace_point.event
      mid   = trace_point.method_id
      printf $stderr, "%*s[debug:event#%d] %s@%s:%d %s\n",
             debug_context.calced_stack_size, "",
             debug_context.thnum,
             event.to_s,
             path,
             line,
             mid.nil? ? "" : mid.to_s
    end
  end

  def check_thread_contexts
    @@rdebug_threads_tbl.delete_if do |thread, value|
      return true if !value
      return true if !is_living_thread(thread)
      return false
    end
  end

  def remove_from_locked
    return nil if @@locked_threads.empty?
    return @@locked_threads.shift;
  end

  def trace_cleanup(debug_context)
    next_thread = nil
    debug_context.stop_reason = DebugContext::CTX_STOP_NONE

    # check that all contexts point to alive threads
    if @@hook_count - @@last_check > 3000
        check_thread_contexts();
        @@last_check = @@hook_count;
    end

    # release a lock
    @@locker = nil;

    # let the next thread to run
    next_thread = remove_from_locked();
    next_thread.run unless next_thread.nil?
  end

  def trace_common(tp, debug_context, current_thread)
    @@hook_count += 1

    return false if debug_context.flag_test(DebugContext::CTX_FL_IGNORE)

    halt_while_other_thread_is_active(current_thread, debug_context)

    return false unless @@locker.nil?
    @@locker = current_thread
    if debug_context.flag_test(DebugContext::CTX_FL_SKIPPED)
      trace_cleanup(debug_context)
      return false
    end

    # There can be many event calls per line, but we only want *one* breakpoint per line. */
    if debug_context.last_line != tp.lineno || debug_context.last_file != tp.path
        debug_context.flag_set(DebugContext::CTX_FL_ENABLE_BKPT)
    end

    return true;
  end

  def line_tracepoint(tp)
    current_thread = Thread.current
    (context, debug_context) = thread_context_lookup(current_thread, nil, nil, true)
    trace_debug_print(tp, debug_context);
    return unless trace_common(tp, debug_context, current_thread)

    file = tp.path
    line = tp.lineno

    if @@tracing || debug_context.flag_test(DebugContext::CTX_FL_TRACING)
      call_at_tracing(context, debug_context, file, line)
    end

    if debug_context.dest_frame == -1 || dc_stack_size(debug_context) == debug_context.dest_frame
      debug_context.stop_next -= 1  if !debug_context.flag_test(DebugContext::CTX_FL_FORCE_MOVE)
      debug_context.stop_next =  -1 if !debug_context.stop_next < 0
      if debug_context.flag_test(DebugContext::CTX_FL_STEPPED) && !debug_context.flag_test(DebugContext::CTX_FL_FORCE_MOVE)
        debug_context.stop_line -= 1
        debug_context.unset(DebugContext::CTX_FL_STEPPED)
      elsif dc_stack_size(debug_context) < debug_context.dest_frame
        debug_context.stop_next = 0
      end
    end

    if (debug_context.stop_next == 0 ||
        debug_context.stop_line == 0 ||
        breakpoint = check_breakpoints_by_pos(debug_context, file, line))
      call_at_line_check(tp, debug_context, breakpoint, context,file, line)
    end
    trace_cleanup(debug_context)
  end

  def register_debug_trace_points
    traces = @@tracepoints
    if traces.nil?
      traces = []
      traces.push(TracePoint.new(:line, &method(:line_tracepoint)))
      # traces.push(TracePoint.new(:call){|tp| self.call_tracepoint(tp)})
      # traces.push(TracePoint.new(:raise){|tp| self.raise_tracepoint(tp)})
      # traces.push(TracePoint.new(:return, :end){|tp| self.return_tracepoint(tp)})
      # traces.push(TracePoint.new(:c_call, :b_call,){|tp| self.misc_call_tracepoint(tp)})
      # traces.push(TracePoint.new(:c_return, :b_return){|tp| self.misc_return_tracepoint(tp)})
      @@tracepoints = traces

      traces.each do |tp|
        tp.enable
      end
    end
  end

  def clear_debug_trace_points
    @@trace_points.each do |tp|
      tp.disable
    end
  end

  def add_to_locked(thread)
    return if @@locked_threads.include?(thread)
    @@locked_threads.push(thread)
  end

  def halt_while_other_thread_is_active(current_thread, debug_context)
    while 1 do
      while !@@locker.nil? && @@locker != current_thread do
        add_to_locked(current_thread)
        Thread.stop();
      end

      if debug_context.flag_test(DebugContext::CTX_FL_SUSPEND) && @@locker != current_thread
        debug_context.flag_set(DebugContext::CTX_FL_WAS_RUNNING)
        Thread.stop();
      else
        break
      end
    end
  end

  def open_debug_inspector(cwi)
    RubyVM::DebugInspector.open do |dc|
      inspected_frame = []
      locs = dc.backtrace_locations
      locs.size.times do |i|
        frame = []
        frame.push(locs[i])
        frame.push(dc.frame_class[i])
        frame.push(dc.frame_bindings[i])
        frame.push(dc.frame_iseq[i])

        inspected_frame.push(frame)
      end
    end

    cwi.debug_context.inspected_frame = inspected_frame
    return cwi.context.send(cwi.method, *cwi.argv)
  end

  def close_debug_inspector(cwi)
    cwi.debug_context.inspected_frame = nil
    return nil
  end

  def call_with_debug_inspector(data)
    begin
      open_debug_inspector(data)
    ensure
      close_debug_inspector(data)
    end
  end

  def save_current_position(debug_context, file, line)
    debug_context.last_file = file
    debug_context.last_line = line
    debug_context.flag_unset(DebugContext::CTX_FL_ENABLE_BKPT)
    debug_context.flag_unset(DebugContext::CTX_FL_STEPPED)
    debug_context.flag_unset(DebugContext::CTX_FL_FORCE_MOVE)
  end

  def call_at(context, debug_context, method, a0, a1)
    cwi = CallWithInspectionData.new
    cwi.debug_context = debug_context
    cwi.context = context
    cwi.method = method
    cwi.argv = [a0, a1]
    return call_with_debug_inspector(cwi)
  end

  def call_at_tracing(context, debug_context, file, line)
    call_at(context, debug_context, "at_tracing", file, line);
  end

  def call_at_line(context, debug_context, file, line)
    save_current_position(debug_context, file, line);
    return call_at(context, debug_context, "at_line", file, line);
  end

  def call_at_breakpoint(context, debug_context, breakpoint)
    debug_context.stop_reason = DebugContext::CTX_STOP_BREAKPOINT
    return call_at(context, debug_context, "at_breakpoint", breakpoint, 0);
  end

  def reset_stepping_stop_points(debug_context)
    debug_context.dest_frame = -1;
    debug_context.stop_line  = -1;
    debug_context.stop_next  = -1;
  end

  def call_at_line_check(binding, debug_context, breakpoint, context, file, line)
    debug_context.stop_reason = DebugContext::CTX_STOP_NONE

    if breakpoint != nil
      if breakpoint != debug_context.breakpoint
        call_at_breakpoint(context, debug_context, breakpoint)
      else
        debug_context.breakpoint = nil
      end
    end
    reset_stepping_stop_points(debug_context);
    call_at_line(context, debug_context, file, line);
  end

end

module_function
  def started?
    !@@rdebug_threads_tbl.nil?
  end

  def start_
    result = false
    @@start_count += 1

    if !self.started?
      @@locker = nil
      @@rdebug_breakpoints = [];
      @@rdebug_catchpoints = {};
      @@rdebug_threads_tbl = {};

      result = true
    end
  end

  def stop
  end

  def started?
  end

  def breakpoints
  end

  def add_breakpoint
  end

  def remove_breakpoint
  end

  def add_catchpoint
  end

  def catchpoints
  end

  def last_context
  end

  def contexts
  end

  def current_context
  end

  def thread_context
  end

  def suspend
  end

  def resume
  end

  def tracing
  end

  def tracing=
  end

  def debug_load
  end

  def skip
  end

  def debug_at_exit
  end

  def post_mortem?
  end

  def post_mortem=
  end

  def keep_frame_binding?
  end

  def keep_frame_binding=
  end

  def track_frame_args?
  end

  def track_frame_args=
  end

  def debug
  end

  def debug=
  end

  class DebugThread < Thread
    def self.inherited(someone)
    end
  end

  class CallWithInspectionData
    attr_accessor :debug_context, :context, :method, :argv
  end
end
