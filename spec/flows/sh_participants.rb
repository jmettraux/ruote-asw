
#
# spec'ing ruote-asw
#
# Fri Jan  4 21:09:36 JST 2013
#


shared_examples_for 'flows with participants' do

  it 'flips burgers' do


    @dboard.register do
      nichts Ruote::NullParticipant
    end

    pdef = Ruote.define { nichts }

    wfid = @dboard.launch(pdef)
    @dboard.wait_for('decision_done')
    @dboard.wait_for('dispatched', :timeout => 10)
  end
end

