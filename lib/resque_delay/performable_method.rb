module ResqueDelay
  class PerformableMethod < Struct.new(:object, :method, :args, :queue, :run_in)
    CLASS_STRING_FORMAT = /^CLASS\:([A-Z][\w\:]+)$/
    AR_STRING_FORMAT    = /^AR\:([A-Z][\w\:]+)\:(\d+)$/
    DM_STRING_FORMAT    = /^DM\:((?:[A-Z][a-zA-z]+)(?:\:\:[A-Z][a-zA-z]+)*)\:([\d\:]+)$/
    MG_STRING_FORMAT    = /^MG\:([A-Z][\w\:]+)\:(\w+)$/
    
    def self.create(object, method, args, queue, run_in)
      raise NoMethodError, "undefined method `#{method}' for #{object.inspect}" unless object.respond_to?(method, true)
      self.new(object, method, args, queue, run_in)
    end

    def initialize(object, method, args, queue, run_in)
      self.object = dump(object)
      self.args   = args.map { |a| dump(a) }
      self.method = method.to_sym
      self.queue = queue
      self.run_in = run_in
    end

    def display_name
      case self.object
      when CLASS_STRING_FORMAT then "#{$1}.#{method}"
      when AR_STRING_FORMAT    then "#{$1}##{method}"
      when DM_STRING_FORMAT    then "#{$1}##{method}"
      when MG_STRING_FORMAT    then "#{$1}##{method}"        
      else "Unknown##{method}"
      end
    end

    def perform
      load(object).send(method, *args.map { |a| load(a) })
    rescue => e
      if defined?(ActiveRecord) && e.kind_of?(ActiveRecord::RecordNotFound)
        true
      else
        raise
      end
    end

    private

    def load(arg)      
      case arg
      when CLASS_STRING_FORMAT then $1.constantize
      when AR_STRING_FORMAT    then $1.constantize.find($2)
      when DM_STRING_FORMAT    then $1.constantize.get!(*$2.split(':'))
      when MG_STRING_FORMAT    then $1.constantize.find($2)        
      else arg
      end
    end

    def dump(arg)
      if arg.kind_of?(Class) || arg.kind_of?(Module)
        class_to_string(arg)
      elsif defined?(ActiveRecord) && arg.kind_of?(ActiveRecord::Base)
        ar_to_string(arg)
      elsif defined?(DataMapper) && arg.kind_of?(DataMapper::Resource)
        dm_to_string(arg)
      elsif defined?(Mongoid) && arg.kind_of?(Mongoid::Document)
        mg_to_string(arg)          
      else
        arg
      end
    end
    
    def mg_to_string(obj)
      "MG:#{obj.class}:#{obj.id}"
    end

    def ar_to_string(obj)
      "AR:#{obj.class}:#{obj.id}"
    end

    def dm_to_string(obj)
      "DM:#{obj.class}:#{obj.key.join(':')}"
    end

    def class_to_string(obj)
      "CLASS:#{obj.name}"
    end
  end
end