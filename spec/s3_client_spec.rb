
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

    it 'uploads a file to S3' do

      fname = "s3_spec_#{Time.now.to_i}_#{$$}_#{Thread.object_id}.txt"

      r = client.put(fname, 'test 1 2 3')

      r.code.should == 200

      client.get(fname).body.should == 'test 1 2 3'
    end
  end

  describe '#get' do

    it 'retrieves a file from S3' do

      fname = "s3_spec_#{Time.now.to_i}_#{$$}_#{Thread.object_id}.txt"
      client.put(fname, "hello from Tokyo S3\n")

      client.get(fname).body.should == "hello from Tokyo S3\n"
    end
  end

  describe '#delete' do

    it 'deletes a file' do

      fname = "s3_spec_#{Time.now.to_i}_#{$$}_#{Thread.object_id}.txt"
      client.put(fname, 'test 3 2 1')

      r = client.delete(fname)

      r.code.should == 204

      client.get(fname).code.should == 404
    end
  end

  describe '#list' do

    it 'lists the filenames in the bucket'
  end

  describe '#purge' do

    it 'deletes all the files in the bucket'
  end
end

