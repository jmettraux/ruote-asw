
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

  it 'sets timers and they trigger the schedule' do

    @dboard.register :nichts, Ruote::NullParticipant

    pdef =
      Ruote.define do
        wait '5s'
        nichts
      end

    wfid = @dboard.launch(pdef)
    @dboard.wait_for('decision_done')

    @dboard.storage.store.get_execution(wfid)['schedules'].size.should == 1

    @dboard.wait_for('dispatched')

    @dboard.storage.store.get_execution(wfid)['schedules'].size.should == 0
  end
end

