
#
# spec'ing ruote-asw
#
# Fri Jan  4 21:09:36 JST 2013
#


shared_examples_for 'participants' do

  it 'stores the participant list' do


    @dboard.register do
      alpha Ruote::StorageParticipant
    end

    plist = @dboard.storage.get('configurations', 'participant_list')['list']

    plist[0][0].should == '^alpha$'
  end
end

