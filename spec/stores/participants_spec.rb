
#
# spec'ing ruote-asw
#
# Fri Jan  4 21:09:36 JST 2013
#

require 'spec_helper'


describe 'the ruote-asw store' do

  before(:each) do

    setup_dboard
  end

  after(:each) do

    teardown_dboard
  end

  it 'stores the participant list' do

    @dboard.register do
      alpha Ruote::StorageParticipant
    end

    plist = @dboard.storage.get('configurations', 'participant_list')['list']

    plist[0][0].should == '^alpha$'
  end
end

