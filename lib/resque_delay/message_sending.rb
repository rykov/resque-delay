require 'active_support/basic_object'
module ResqueDelay
  class DelayProxy < ActiveSupport::BasicObject
    def initialize(target, options)
      @target = target
      @options = options
      if @options[:in].not_nil? && !@options[:in].kind_of?(::Fixnum)
        raise ::ArgumentError.new("Delayed settings must be a Fixnum! not a #{@options[:in].class.name}") 
      end
    end

    def method_missing(method, *args)
      queue = @options[:to] || :default
      performable_method = PerformableMethod.create(@target, method, args)
      if delay?
        ::Resque.enqueue_in_with_queue(queue, delay, DelayProxy, performable_method )
      else
        ::Resque::Job.create(queue, DelayProxy, performable_method)
      end
    end

    # Called asynchrously by Resque
    def self.perform(args)
      PerformableMethod.new(*args).perform
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