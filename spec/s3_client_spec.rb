
#
# spec'ing ruote-asw
#
# Tue Dec 25 07:46:47 JST 2012
#

require 'spec_helper'


describe Ruote::Asw::S3Client do

  context 'routine operation' do

    def new_fname

      "s3_spec_#{Time.now.to_i}_#{$$}_#{Thread.object_id}.txt"
    end

    let(:client) {

      Ruote::Asw::S3Client.new(
        ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'], 'ruote-asw')
    }

    describe '#put' do

      it 'uploads a file to S3' do

        fname = new_fname

        r = client.put(fname, 'test 1 2 3')

        r.should == nil
        client.get(fname).should == 'test 1 2 3'
      end
    end

    describe '#get' do

      it 'retrieves a file from S3' do

        fname = new_fname
        client.put(fname, 'hello from Tokyo S3')

        client.get(fname).should == 'hello from Tokyo S3'
      end

      it 'returns nil if there is no file' do

        client.get('nada.txt').should == nil
      end
    end

    describe '#delete' do

      it 'deletes a file' do

        fname = new_fname
        client.put(fname, 'test 3 2 1')

        r = client.delete(fname)

        r.should == nil
        client.get(fname).should == nil
      end
    end

    describe '#list' do

      it 'lists the filenames in the bucket' do

        fnames = [ new_fname, new_fname, new_fname ]
        fnames.each { |fn| client.put(fn, 'oh hai!') }

        l = client.list

        l.class.should == Array
        (fnames - l).should == []
      end
    end

    describe '#purge' do

      it 'deletes all the files in the bucket' do

        fnames = [ new_fname, new_fname, new_fname ]
        fnames.each { |fn| client.put(fn, 'oh hai!') }

        r = client.purge

        r.should == nil
        client.list.should == []
      end
    end
  end

  context 'bucket creation/deletion' do

    describe '.list_buckets' do

      it 'lists the buckets in the account' do

        l = Ruote::Asw::S3Client.list_buckets(
          ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])

        l.should include('ruote-asw')
      end
    end

    describe '#create_bucket' do

      it 'creates a bucket'
    end

    describe '#delete_bucket' do

      it 'deletes a bucket'
    end
  end
end

