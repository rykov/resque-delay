require 'active_support/basic_object'

module ResqueDelay
  class DelayProxy < ActiveSupport::BasicObject
    def initialize(target, options)
      @target = target
      @options = options
    end

    def method_missing(method, *args)
      queue = @options[:to] || :default
      performable_method = PerformableMethod.create(@target, method, args)
      ::Resque::Job.create(queue, DelayProxy, performable_method)
    end

    # Called asynchrously by Resque
    def self.perform(args)
      PerformableMethod.new(*args).perform
    end
  end

  module MessageSending
    def delay_with_resque(options = {})
      DelayProxy.new(self, options)
    end
  end
end