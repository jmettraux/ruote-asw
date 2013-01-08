
#
# spec'ing ruote-asw
#
# Fri Jan  4 21:09:36 JST 2013
#

require 'spec_helper'


describe 'ruote-asw and flows' do

  before(:each) do

    setup_dboard
  end

  after(:each) do

    teardown_dboard
  end

  it 'dispatches to participants' do

    @dboard.register do
      nichts Ruote::NullParticipant
    end

    pdef = Ruote.define { nichts }

    wfid = @dboard.launch(pdef)
    @dboard.wait_for('decision_done')
    @dboard.wait_for('dispatched')

    ps = @dboard.ps(wfid)
    ps.expressions.size.should == 2
    ps.errors.size.should == 0

    @dboard.storage.expression_wfids.should == [ wfid ]

    #@dboard.storage.open_executions.size.should == 1
      # too eventually consistent...
  end

  it 'receives from participants' do

    @dboard.register 'stamp' do |workitem|
      workitem.fields['dennou'] = 'coil'
    end

    pdef = Ruote.define { stamp }

    wfid = @dboard.launch(pdef)
    @dboard.wait_for('decision_done')
    @dboard.wait_for('dispatch')
    @dboard.wait_for('receive')

    r = @dboard.wait_for(wfid, :timeout => 60)

    r['action'].should == 'terminated'
    r['workitem']['fields']['dennou'].should == 'coil'
  end

  it 'passes back errors in participants' do

    @dboard.register 'murphy' do |workitem|
      raise 'murphy!'
    end

    pdef = Ruote.define { murphy }

    wfid = @dboard.launch(pdef)
    @dboard.wait_for('error_intercepted')
    @dboard.wait_for('decision_done')

    ps = @dboard.ps(wfid)
    ps.expressions.size.should == 2
    ps.errors.size.should == 1
    ps.errors.first.message.should == '#<RuntimeError: murphy!>'

    @dboard.storage.expression_wfids.should == [ wfid ]

    #@dboard.storage.open_executions.size.should == 1
      # too eventually consistent...
  end
end

