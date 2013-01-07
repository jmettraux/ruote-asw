
#
# spec'ing ruote-asw
#
# Thu Dec 27 09:33:30 JST 2012
#
# Onomichi
#

require 'spec_helper'


describe 'the ruote-asw store' do

  before(:each) do

    setup_dboard
  end

  after(:each) do

    teardown_dboard
  end

  it 'is empty when the flow terminates' do

    pdef =
      Ruote.define do
      end

    wfid = @dboard.launch(pdef)

    @dboard.wait_for('decision_done')

    @dboard.processes.should be_empty

    @dboard.storage.expression_wfids.should == []
    @dboard.storage.store.get_execution(wfid).should == nil
  end

  it 'retains the state when the flow stalls' do

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

    #@dboard.storage.open_executions.should_not be_empty
      # too eventually consistent
  end
end

