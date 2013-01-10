
#
# spec'ing ruote-asw
#
# Thu Jan 10 21:46:44 JST 2013
#
# "ii kara, detteitte"
#

require 'spec_helper'


describe 'ruote-asw and flows' do

  before(:each) do

    setup_dboard
  end

  after(:each) do

    teardown_dboard
  end

  it 'sets timers and react to their triggers' do

    pdef = Ruote.define { wait '3s' }

    wfid = @dboard.launch(pdef)
    r = @dboard.wait_for(wfid)

    r['action'].should == 'terminated'
  end
end

