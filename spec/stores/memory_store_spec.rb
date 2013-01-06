
#
# spec'ing ruote-asw
#
# Thu Dec 27 09:33:30 JST 2012
#
# Onomichi
#

require 'spec_helper'


describe Ruote::Asw::MemoryStore do

  before(:each) do

    setup_dboard_with_memory_store
  end

  after(:each) do

    teardown_dboard
  end

  it_behaves_like 'a store'
  it_flows_with 'participants'
end

