
#
# spec'ing ruote-asw
#
# Tue Dec 25 07:46:47 JST 2012
#

require 'spec_helper'


describe Ruote::Asw::S3Client do

  let(:client) {

    Ruote::Asw::S3Client.new(
      ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'], 'ruote-asw')
  }

  describe '#put' do

    it 'works'
  end

  describe '#get' do

    it 'retrieves a file from S3' do

      pp client.get('hello.txt')
    end
  end

  describe '#delete' do

    it 'deletes a file'
  end

  describe '#purge' do

    it 'deletes all the files in the bucket'
  end
end

