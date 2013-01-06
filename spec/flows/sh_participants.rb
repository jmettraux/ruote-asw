
#
# spec'ing ruote-asw
#
# Fri Jan  4 21:09:36 JST 2013
#


shared_examples_for 'flows with participants' do

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
    @dboard.storage.open_executions.size.should == 1
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

  it 'passes back error in participants to the decision side'
end

