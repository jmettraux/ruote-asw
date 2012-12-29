#--
# Copyright (c) 2012-2013, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


namespace :s3 do

  task :req do

    require 'ruote-asw'
  end

  desc %{
    list the buckets the AWS account owns
  }
  task :buckets => :req do

    pp Ruote::Asw::S3Client.list_buckets(
      ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
  end

  desc %{
    creates a bucket given a name and an AWS region
  }
  task :create_bucket, [ :name, :region ] => :req do |t, args|

    Ruote::Asw::S3Client.create_bucket(
      ENV['AWS_ACCESS_KEY_ID'],
      ENV['AWS_SECRET_ACCESS_KEY'],
      args[:name],
      args[:region])
  end

  desc %{
    deletes a bucket
  }
  task :delete_bucket, [ :name ] => :req do |t, args|

    Ruote::Asw::S3Client.delete_bucket(
      ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'], args[:name])
  end

  desc %{
    removes all the items in the target bucket
  }
  task :purge_bucket, [ :name ] => :req do |t, args|

    Ruote::Asw::S3Client.new(
      nil, ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'], args[:name]
    ).purge
  end
end

