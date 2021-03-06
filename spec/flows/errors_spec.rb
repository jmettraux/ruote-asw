
#
# spec'ing ruote-asw
#
# Fri Jan  4 21:33:24 JST 2013
#

require 'spec_helper'


describe 'ruote-asw and flows' do

  before(:each) do

    setup_dboard
  end

  after(:each) do

    teardown_dboard
  end

  it 'stores the error' do

    pdef = Ruote.define { nada }

    wfid = @dboard.launch(pdef)
    @dboard.wait_for('decision_done')

    ps = @dboard.ps(wfid)

    ps.errors.size.should ==
      1
    ps.errors.first.message.should ==
      "#<RuntimeError: unknown participant or subprocess 'nada'>"
  end
end

