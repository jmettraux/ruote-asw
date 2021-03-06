
#
# spec'ing ruote-asw
#
# Tue Jul  2 13:21:00 JST 2013
#

require 'spec_helper'


describe 'ruote-asw and flows' do

  before(:each) do

    setup_dboard
  end

  after(:each) do

    teardown_dboard
  end

  it 'triggers in-process trackers' do

    @dboard.register :alpha, Ruote::NoOpParticipant

    pdef =
      Ruote.define do
        concurrence do
          sequence do
            listen :to => 'alpha'
            set 'v:/seen' => true
          end
          sequence do
            alpha
          end
        end
      end

    wfid = @dboard.launch(pdef)
    r = @dboard.wait_for(wfid)

    r['action'].should == 'terminated'
    r['variables']['seen'].should == true
  end
end

