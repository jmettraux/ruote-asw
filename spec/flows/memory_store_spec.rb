
#
# spec'ing ruote-asw
#
# Fri Jan  4 21:27:31 JST 2013
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

  it_orchestrates 'flows with errors'
  it_orchestrates 'flows with participants'
end

