
#
# spec'ing ruote-asw
#
# Thu Dec 27 09:33:30 JST 2012
#
# Onomichi
#

require 'spec_helper'


shared_examples 'a store' do

  it 'is empty when the flow terminates' do

    pdef =
      Ruote.define do
      end

    wfid = @dboard.launch(pdef)

    @dboard.wait_for('decision_done')

    @dboard.processes.should be_empty

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

    @dboard.storage.open_executions.should_not be_empty
  end
end
