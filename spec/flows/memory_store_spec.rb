
#
# spec'ing ruote-asw
#
# Fri Jan  4 21:27:31 JST 2013
#

require 'spec_helper'


describe Ruote::Asw::MemoryStore do

  before(:each) do

    setup_dboard_with_memory_store
  end

  after(:each) do

    teardown_dboard
  end

  it_orchestrates 'flows with errors'
  it_orchestrates 'flows with participants'
end

