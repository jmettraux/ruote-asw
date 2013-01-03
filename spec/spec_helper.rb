
$:.unshift(File.expand_path('../../lib', __FILE__))

require 'rufus-json/automatic'
require 'ruote-asw'

# leverage the same connection the ruote functional tests use
#
require File.expand_path('../../test/connection.rb', __FILE__)

# require all the shared examples
#
Dir[File.expand_path('../**/shared*.rb', __FILE__)].each { |pa| require(pa) }


#RSpec.configure do |config|
#end

