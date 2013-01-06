
$:.unshift(File.expand_path('../../lib', __FILE__))

require 'rufus-json/automatic'
require 'ruote-asw'

# leverage the same connection the ruote functional tests use
#
require File.expand_path('../../test/connection.rb', __FILE__)

# require all the support code
#
Dir[File.expand_path('../support/*.rb', __FILE__)].each { |pa| require(pa) }

# require all the shared examples
#
Dir[File.expand_path('../**/sh_*.rb', __FILE__)].each { |pa| require(pa) }


RSpec.configure do |c|

  c.alias_it_should_behave_like_to :it_flows_with, 'flows with'
  c.alias_it_should_behave_like_to :it_orchestrates, 'orchestrates'
end

