
#
# spec'ing ruote-asw
#
# Thu Dec 27 09:33:30 JST 2012
#
# Onomichi
#

require 'spec_helper'


describe 'ruote-asw with a MemoryStore' do

  before(:each) do

    @dboard =
      Ruote::Dashboard.new(
        Ruote::Asw::DecisionWorker.new(
        Ruote::Asw::ActivityWorker.new(
          new_storage(:memory_store => true, :no_preparation => true))))
  end

  after(:each) do

    @dboard.shutdown
    @dboard.storage.purge!
  end

  describe 'sequence' do

    it 'flows from a to b' do

      pdef =
        Ruote.define do
          noop # a
          noop # b
        end

      wfid = @dboard.launch(pdef)

      p wfid
      sleep(7)
      sleep(7)
    end
  end
end

