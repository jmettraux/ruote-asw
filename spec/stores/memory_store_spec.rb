
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

    @dboard =
      Ruote::Dashboard.new(
        Ruote::Asw::DecisionWorker.new(
        Ruote::Asw::ActivityWorker.new(
          new_storage(:memory_store => true, :no_preparation => true))))

    @dboard.noisy = (ENV['NOISY'] == 'true')
  end

  after(:each) do

    @dboard.shutdown
    @dboard.storage.purge!
  end

  it_behaves_like 'a store'
  it_flows_with 'participants'
end

