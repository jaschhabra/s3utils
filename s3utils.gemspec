$:.push File.expand_path("../lib", __FILE__)
require "s3utils/version"

Gem::Specification.new do |s|
  s.name        = "s3utils"
  s.version     = S3Utils::VERSION
  s.authors     = ["Jasmeet Chhabra"]
  s.email       = ["jasmeet@chhabra-inc.com"]
  s.homepage    = "https://github.com/jasmeetc/s3utils"
  s.summary     = %q{Simple tool for working with S3. Similar to s3cmd that comes with s3sync}
  s.description = <<-DESC
Provides a s3cmd binary to perform simple commands on buckets and objects in s3. 
See https://github.com/jasmeetc/s3utils for more.
DESC

  s.required_ruby_version = ">= 1.8.7"

  s.files       = Dir["bin/*", "lib/**/*"] + ["LICENSE", "README.md"]
  s.executables = ["s3cmd"]

  s.add_dependency "aws-sdk", "~> 1.6.0"
  s.add_dependency "thor", "~> 0.15.4"
end
