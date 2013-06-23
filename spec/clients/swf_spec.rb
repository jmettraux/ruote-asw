
#
# spec'ing ruote-asw
#
# Mon Dec 24 18:03:38 JST 2012
#

require 'spec_helper'


describe Ruote::Asw::SwfClient do

  let(:client) {

    Ruote::Asw::SwfClient.new(nil, RA.aki, RA.sak, RA.region)
  }

  describe '#list_domains' do

    it 'lists SWF domains' do

      h = client.list_domains(:registration_status => 'REGISTERED')

      h['domainInfos'].should_not == nil
    end
  end
end

