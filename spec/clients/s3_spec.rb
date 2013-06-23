
#
# spec'ing ruote-asw
#
# Tue Dec 25 07:46:47 JST 2012
#

require 'spec_helper'


describe Ruote::Asw::S3Client do

  def new_bucket_name

    "ruote-aws-s3-spec-#{Time.now.to_i}#{$$}#{Thread.object_id}"
  end

  let(:aki) { RA.aki }
  let(:sak) { RA.sak }

  context 'routine operation' do

    def new_fname

      "s3_spec_#{Time.now.to_i}_#{$$}_#{Thread.object_id}.txt"
    end

    let(:client) {

      Ruote::Asw::S3Client.new(nil, aki, sak, 'ruote-asw')
    }

    describe '#put' do

      it 'uploads a file to S3' do

        fname = new_fname

        r = client.put(fname, 'test 1 2 3')

        r.should == nil
        client.get(fname).should == 'test 1 2 3'
      end

      it 'deflates and uploads .zlib files' do

        fname = new_fname + '.zlib'

        r = client.put(fname, 'Jacques-Antoine-Hippolyte, Comte de Guibert')

        r.should ==
          nil
        client.get(fname).should ==
          'Jacques-Antoine-Hippolyte, Comte de Guibert'
      end

      it 'encodes .json files' do

        fname = new_fname + '.json'

        r = client.put(fname, { 'json' => true, 'customer' => 'Turenne' })

        r.should ==
          nil
        client.get(fname).should ==
          { 'json' => true, 'customer' => 'Turenne' }
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

      it 'returns nil if there is no file (.zlib)' do

        client.get('nada.zlib').should == nil
      end

      it 'returns nil if there is no file (.json)' do

        client.get('nada.json').should == nil
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

      it 'accepts a prefix argument' do

        fnames = %w[ alfred.txt alice.txt bob.txt ]
        fnames.each { |fn| client.put(fn, fn) }

        l = client.list('al')

        l.should == %w[ alfred.txt alice.txt ]
      end

      it 'lists all (multi requests)' do

        bucket = new_bucket_name

        Ruote::Asw::S3Client.create_bucket(aki, sak, bucket, 'ireland')

        client = Ruote::Asw::S3Client.new(nil, aki, sak, bucket)

        20.times { |i| client.put( "file#{i}.txt", 'nada') }

        fnames = client.list(nil, nil, 10)

        fnames.size.should == 20
        fnames.uniq.size.should == 20

        client.purge
        Ruote::Asw::S3Client.delete_bucket(aki, sak, bucket)
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

      it 'raises if the bucket does not exist' do

        lambda {
          Ruote::Asw::S3Client.new(nil, aki, sak, 'nada-nada-nada').purge
        }.should raise_error(
          ArgumentError, "bucket 'nada-nada-nada' doesn't seem to exist"
        )
      end
    end
  end

  context 'bucket creation/deletion' do

    after(:each) do
      #
      # delete all the transient test buckets

      l = Ruote::Asw::S3Client.list_buckets(aki, sak)

      l.each do |n|
        next unless n.match(/^ruote-aws-s3-spec-\d+$/)
        Ruote::Asw::S3Client.delete_bucket(aki, sak, n, true)
      end
    end

    describe '.new' do

      it 'creates the bucket if a region is specified' do

        bn = new_bucket_name

        Ruote::Asw::S3Client.new(nil, aki, sak, bn, 'edo')

        Ruote::Asw::S3Client.list_buckets(aki, sak).should include(bn)
      end

      it 'does not create the bucket if a region is not specified' do

        bn = new_bucket_name

        Ruote::Asw::S3Client.new(nil, aki, sak, bn)

        Ruote::Asw::S3Client.list_buckets(aki, sak).should_not include(bn)
      end

      it 'is ok if the bucket already exists' do

        Ruote::Asw::S3Client.list_buckets(aki, sak).should include('ruote-asw')

        Ruote::Asw::S3Client.new(nil, aki, sak, 'ruote-asw', 'edo')

        Ruote::Asw::S3Client.list_buckets(aki, sak).should include('ruote-asw')
      end
    end

    describe '.exists?(bucket_name)' do

      it 'returns true if the bucket exists (in the account)' do
      end
    end

    describe '.list_buckets' do

      it 'lists the buckets in the account' do

        l = Ruote::Asw::S3Client.list_buckets(aki, sak)

        l.should include('ruote-asw')
      end
    end

    describe '.create_bucket' do

      it 'creates a bucket' do

        bucket = new_bucket_name

        r = Ruote::Asw::S3Client.create_bucket(aki, sak, bucket, 'edo')

        r.should == nil

        l = Ruote::Asw::S3Client.list_buckets(aki, sak)

        l.should include(bucket)
      end

      it 'accepts a quiet option' do

        r = Ruote::Asw::S3Client.create_bucket(
          aki, sak, 'ruote-asw', 'edo', true)

        r.should == nil
      end

      it 'raises if the bucket already exists (same account)' do

        bucket = new_bucket_name

        Ruote::Asw::S3Client.create_bucket(aki, sak, bucket, 'euro')

        lambda {

          Ruote::Asw::S3Client.create_bucket(aki, sak, bucket, 'euro')

        }.should raise_error(ArgumentError)
      end

      it 'raises if the bucket already exists (other account)' do

        lambda {

          Ruote::Asw::S3Client.create_bucket(aki, sak, 'bucket', 'euro')

        }.should raise_error(ArgumentError)
      end

      it 'raises if the region is not a S3 region' do

        lambda {

          Ruote::Asw::S3Client.create_bucket(aki, sak, 'x', '123')

        }.should raise_error(ArgumentError, 'unknown S3 region: "123"')
      end

      it 'raises if region does not exist (but matches region name format)' do

        bucket = new_bucket_name

        region = 'ap-gangnam-1' # south of the river

        lambda {

          Ruote::Asw::S3Client.create_bucket(aki, sak, bucket, region)

        }.should raise_error(
          ArgumentError,
          "InvalidLocationConstraint: " +
          "The specified location-constraint is not valid")
      end
    end

    describe '.delete_bucket' do

      it 'deletes a bucket' do

        bucket = new_bucket_name

        Ruote::Asw::S3Client.create_bucket(aki, sak, bucket, 'edo')

        r = Ruote::Asw::S3Client.delete_bucket(aki, sak, bucket)

        l = Ruote::Asw::S3Client.list_buckets(aki, sak)

        l.should_not include(bucket)
      end
    end
  end
end

