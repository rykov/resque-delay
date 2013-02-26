module ResqueDelay
  class PerformableMethod < Struct.new(:object, :method, :args)
    CLASS_STRING_FORMAT = /^CLASS\:([A-Z][\w\:]+)$/
    AR_STRING_FORMAT    = /^AR\:([A-Z][\w\:]+)\:(\d+)$/
    MG_STRING_FORMAT    = /^MG\:([A-Z][\w\:]+)\:(\w+)$/
    
    def self.create(object, method, args)
      raise NoMethodError, "undefined method `#{method}' for #{object.inspect}" unless object.respond_to?(method)
      self.new(object, method, args)
    end

    def initialize(object, method, args)
      self.object = dump(object)
      self.args   = args.map { |a| dump(a) }
      self.method = method.to_sym
    end
    
    def resque_args
      [object, method, args]
    end

    def display_name
      case self.object
      when CLASS_STRING_FORMAT then "#{$1}.#{method}"
      when AR_STRING_FORMAT    then "#{$1}##{method}"
      when MG_STRING_FORMAT    then "#{$1}##{method}"        
      else "Unknown##{method}"
      end
    end

    def perform
      load(object).send(method, *args.map{|a| load(a)})
    rescue ActiveRecord::RecordNotFound, Mongoid::Errors::DocumentNotFound
      # We cannot do anything about objects which were deleted in the meantime
      true
    end

    private

    def load(arg)      
      case arg
      when CLASS_STRING_FORMAT then $1.constantize
      when AR_STRING_FORMAT    then $1.constantize.find($2)
      when MG_STRING_FORMAT    then $1.constantize.find($2)        
      else arg
      end
    end

    def dump(arg)
      case arg
      when Class              then class_to_string(arg)
      when ActiveRecord::Base then ar_to_string(arg)
      else 
        if defined?(Mongoid) && arg.is_a?(Mongoid::Document)
          mg_to_string(arg)          
        else
          arg
        end
      end
    end
    
    def mg_to_string(obj)
      "MG:#{obj.class}:#{obj.id}"
    end

    def ar_to_string(obj)
      "AR:#{obj.class}:#{obj.id}"
    end

    def class_to_string(obj)
      "CLASS:#{obj.name}"
    end
  end
end