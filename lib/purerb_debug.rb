require 'purerb_debug/context.rb'
module Debugger
  VERSION = 0.1
  @@debug_debugger = false
  @@debug_debugger_stack_size = false

  @@last_context = nil
  @@last_thread  = nil
  @@locker       = nil
  @@tracepoints  = nil

  @@last_debug_context = nil;

  @@rdebug_breakpoints = nil;
  @@rdebug_catchpoints = nil;
  @@rdebug_threads_tbl = nil;

  @@start_count = 0
  @@thnum_max   = 0

  class ThreadsTable
    attr_accessor :tbl
    def initialize
      @tbl = {}
    end
  end

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
    context.calced_stack_size = self.exact_stack_size(thread);

    context.stop_next  = -1;
    context.dest_frame = -1;
    context.stop_line  = -1;
    context.stop_frame = -1;

    context.stop_reason = DebugContext::CTX_STOP_NONE;
    context.thread_id   = ref2id(thread);
    context.breakpoint  = Qnil;
    context.inspected_frame = Qnil;

    if (thread.class == DebugThread)
        DebugContext.CTX_FL_SET(context, DebugContext::CTX_FL_IGNORE);
    end
    return context
  end

  def thread_context_lookup(thread, context, debug_context, create)
    thread_id       = nil
    l_debug_context = nil

    if @@last_thread == thread && !@@last_context.nil?
      return [@@last_context, @@last_debug_context]
    end

    thread_id = thread.object_id
    if !(context = @@rdebug_threads_tbl[thread_id]) || !context
      if create
        context = debug_context_create(thread)
        @@rdebug_threads_tbl[thread_id] = context
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

  def trace_debug_point(trace_point, debug_context)
    if @@debug_debugger == true
      path  = trace_point.path
      line  = trace_point.linno
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

  def line_tracepoint(tp)
    file = line = breakpoint = nil
    current_thread = Thread.current
    (context, debug_context) = thread_context_lookup(current_thread, nil, nil, true)
    trace_debug_print(tp, debug_context);
  end

  def register_debug_trace_points
    traces = @@trace_points
    if traces.nil?
      traces = []
      traces.push(TracePoint.new(:line){|tp| self.line_tracepoint(tp)})
      traces.push(TracePoint.new(:call){|tp| self.call_tracepoint(tp)})
      traces.push(TracePoint.new(:raise){|tp| self.raise_tracepoint(tp)})
      traces.push(TracePoint.new(:return, :end){|tp| self.return_tracepoint(tp)})
      traces.push(TracePoint.new(:c_call, :b_call,){|tp| self.misc_call_tracepoint(tp)})
      traces.push(TracePoint.new(:c_return, :b_return){|tp| self.misc_return_tracepoint(tp)})
      @@trace_points = traces

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

  class ThreadsTable < Object
  end

  class DebugThread < Thread
    def self.inherited(someone)
    end
  end
end
