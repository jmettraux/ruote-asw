
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

    def new_bucket_name

      "ruote-aws-s3-spec-#{Time.now.to_i}#{$$}#{Thread.object_id}"
    end

    after(:each) do
      #
      # delete all the transient test buckets

      l = Ruote::Asw::S3Client.list_buckets(
        ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])

      l.each do |n|
        next unless n.match(/^ruote-aws-s3-spec-\d+$/)
        Ruote::Asw::S3Client.delete_bucket(
          ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'], n)
      end
    end

    describe '.list_buckets' do

      it 'lists the buckets in the account' do

        l = Ruote::Asw::S3Client.list_buckets(
          ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])

        l.should include('ruote-asw')
      end
    end

    describe '.create_bucket' do

      it 'creates a bucket' do

        bucket = new_bucket_name

        r = Ruote::Asw::S3Client.create_bucket(
          ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'], bucket, 'edo')

        r.should == nil

        l = Ruote::Asw::S3Client.list_buckets(
          ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])

        l.should include(bucket)
      end

      it 'raises if the region is not a S3 region' do

        lambda {

          Ruote::Asw::S3Client.create_bucket(
            ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'], 'x', '123')

        }.should raise_error(ArgumentError, 'unknown S3 region: "123"')
      end

      it 'raises if the region does not exist (but matches the region name format)'
    end

    describe '.delete_bucket' do

      it 'deletes a bucket' do

        bucket = new_bucket_name

        Ruote::Asw::S3Client.create_bucket(
          ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'], bucket, 'edo')

        r = Ruote::Asw::S3Client.delete_bucket(
          ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'], bucket)

        l = Ruote::Asw::S3Client.list_buckets(
          ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])

        l.should_not include(bucket)
      end
    end
  end
end

