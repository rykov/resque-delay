require 'active_support/proxy_object'

module ResqueDelay
  class DelayProxy < ActiveSupport::ProxyObject
    def initialize(target, options)
      @target = target
      @options = options
      if !@options[:in].nil? && !@options[:in].kind_of?(::Fixnum)
        raise ::ArgumentError.new("Delayed settings must be a Fixnum! not a #{@options[:in].class.name}") 
      end
    end

    def method_missing(method, *args)
      queue = @options[:to] || :default
      run_in = @options[:in] || 0
      performable_method = PerformableMethod.create(@target, method, args, queue, run_in)
      ::Resque::Job.new(queue, performable_method)
      if delay?
        ::Resque.enqueue_in_with_queue(queue, delay, DelayProxy, performable_method )
      else
        ::Resque::Job.create(queue, DelayProxy, performable_method.resque_args)
      end
      performable_method
    end

    # Called asynchronously by Resque
    def self.perform(args)
      if args.respond_to?(:[])
        PerformableMethod.new(args["object"], args["method"], args["args"], args["queue"], args["run_in"]).perform
      else
        PerformableMethod.new(*args).perform
      end
    end

    private

    def delay?
      delay.to_i > 0
    end

    def delay
      @delay ||= @options[:in]
    end
  end

  module MessageSending
    def delay(options = {})
      DelayProxy.new(self, options)
    end
  end
end