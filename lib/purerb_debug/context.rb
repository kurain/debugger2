class DebugContext
  CTX_STOP_NONE       = 0
  CTX_STOP_STEP       = 1
  CTX_STOP_BREAKPOINT = 2
  CTX_STOP_CATCHPOINT = 3

  CTX_FL_SUSPEND      = (1<<1) # suspend because another thread stopping
  CTX_FL_TRACING      = (1<<2) # call at_tracing method
  CTX_FL_SKIPPED      = (1<<3) # skip all debugger events
  CTX_FL_IGNORE       = (1<<4) # this context belongs to ignored thread
  CTX_FL_DEAD         = (1<<5) # this context belonged to died thraed
  CTX_FL_WAS_RUNNING  = (1<<6) # previous thread state
  CTX_FL_ENABLE_BKPT  = (1<<7) # can check breakpoint
  CTX_FL_STEPPED      = (1<<8)
  CTX_FL_FORCE_MOVE   = (1<<9)
  CTX_FL_CATCHING     = (1<<10)

  attr_accessor :thread_id, :thnum, :flags, :calced_stack_size, :stop_reason,
    :stop_next, :dest_frame, :stop_line, :stop_frame, :thread_pause, :last_file, :last_line,
    :breakpoint, :inspected_frame

  def dump(set, flag)
    printf $stderr, "[CTX %s:%d] %s %s\n", __FILE__, __LINE__, set ? "set" : "unset", self.flag_name(f)
  end

  def flag_name(flag)
    case flag
    when CTX_FL_SUSPEND      then 'CTX_FL_SUSPEND'
    when CTX_FL_SUSPEND      then 'CTX_FL_SUSPEND'
    when CTX_FL_TRACING      then 'CTX_FL_TRACING'
    when CTX_FL_SKIPPED      then 'CTX_FL_SKIPPED'
    when CTX_FL_IGNORE       then 'CTX_FL_IGNORE'
    when CTX_FL_DEAD         then 'CTX_FL_DEAD'
    when CTX_FL_WAS_RUNNING  then 'CTX_FL_WAS_RUNNING'
    when CTX_FL_ENABLE_BKPT  then 'CTX_FL_ENABLE_BKPT'
    when CTX_FL_STEPPED      then 'CTX_FL_STEPPED'
    when CTX_FL_FORCE_MOVE   then 'CTX_FL_FORCE_MOVE'
    when CTX_FL_CATCHING     then 'CTX_FL_CATCHING'
    else
      "unkown"
    end
  end

  def flag_test(flag)
    @flags & flag
  end
  def flag_set(flag)
    self.dump(1, flag)
    @flags |= flag
  end

  def flag_unset(flag)
    self.dump(0, flag)
    @flags |= flag
  end
end
