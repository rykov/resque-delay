Gem::Specification.new do |s|
  s.name              = "resque-delay"
  s.version           = "0.6.0"
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "Enable send_later/delay for Resque"
  s.homepage          = "http://github.com/rykov/resque-delay"
  s.email             = "mrykov@gmail"
  s.authors           = [ "Michael Rykov" ]
  s.has_rdoc          = false

  s.files             = %w( README.md Rakefile LICENSE )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("test/**/*")
  s.files            += Dir.glob("spec/**/*")

  s.add_dependency    "resque", ">= 1.25"
  s.add_dependency    "resque-scheduler", ">= 4.0.0"
  s.add_development_dependency "guard"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "coveralls"

  s.description = <<DESCRIPTION
Enable send_later support for Resque
DESCRIPTION
end
