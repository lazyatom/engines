require 'logger'

module Engines
  # The DummyLogger is a class which might pass through to a real Logger
  # if one is assigned. However, it can gracefully swallow any logging calls
  # if there is now Logger assigned.
  class LoggerWrapper
    def initialize(logger=nil)
      set_logger(logger)
    end
    # Assign the 'real' Logger instance that this dummy instance wraps around.
    def set_logger(logger)
      @logger = logger
    end
    # log using the appropriate method if we have a logger
    # if we dont' have a logger, ignore completely.
    def method_missing(name, *args)
      if @logger && @logger.respond_to?(name)
        @logger.send(name, *args)
      end
    end
  end

  LOGGER = Engines::LoggerWrapper.new

  class << self
    
    #--------------------------------------------------------------------------
    # Initialising the logger
    #++------------------------------------------------------------------------
    
    # Create a new Logger instance for Engines, with the given outputter and level    
    def create_logger(outputter=STDOUT, level=Logger::INFO)
      LOGGER.set_logger(Logger.new(outputter, level))
    end
    # Sets the Logger instance that Engines will use to send logging information to
    def set_logger(logger)
      Engines::LOGGER.set_logger(logger) # TODO: no need for Engines:: part
    end
    # Retrieves the current Logger instance
    def log
      Engines::LOGGER # TODO: no need for Engines:: part
    end
    alias :logger :log
  end
end  