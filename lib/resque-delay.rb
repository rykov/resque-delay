require 'resque_delay/performable_method'
require 'resque_delay/message_sending'

Object.send(:include, ResqueDelay::MessageSending)