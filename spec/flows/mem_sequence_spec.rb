
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

    @dboard.noisy = (ENV['NOISY'] == 'true')
  end

  after(:each) do

    @dboard.shutdown
    @dboard.storage.purge!
  end

  it 'flows from a to b' do

    pdef =
      Ruote.define do
        noop # a
        noop # b
      end

    wfid = @dboard.launch(pdef)

    @dboard.wait_for('decision_done')

    @dboard.processes.should be_empty

    @dboard.storage.store.get_execution(wfid).should == nil
  end

  it 'stalls and state is preserved' do

    pdef =
      Ruote.define do
        stall
      end

    wfid = @dboard.launch(pdef)

    @dboard.wait_for('decision_done')

    @dboard.storage.expression_wfids.should == [ wfid ]
    @dboard.processes.size.should == 1

    ps = @dboard.ps(wfid)

    ps.expressions.size.should == 2
    ps.errors.size.should == 0

    @dboard.storage.open_executions.should_not be_empty
  end
end

