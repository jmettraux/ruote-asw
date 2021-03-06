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

require 'ruote/asw/stores/store'
require 'ruote/asw/clients/s3'


module Ruote::Asw

  class S3Store < Store

    def initialize(aki, sak, region, bucket)

      super()

      Ruote::Asw::S3Client.create_bucket(aki, sak, bucket, region, true)
        #
        # 'quiet' is set to true, will not complain if the
        # bucket already exists...

      @client = Ruote::Asw::S3Client.new(self, aki, sak, bucket)
    end

    def load_system

      @client.get('system.json.zlib') ||
      {
        'configurations' => { 'engine' => {} },
        'variables' => {}
      }
    end

    def put(doc, opts)

      sys = load_system
      sys[doc['type']][doc['_id']] = doc

      @client.put('system.json.zlib', sys)

      doc
    end

    def get_execution(wfid)

      @client.get("wf-#{wfid}.json.zlib")
    end

    def put_execution(wfid, execution)

      @client.put("wf-#{wfid}.json.zlib", execution)

      nil
    end

    def del_execution(wfid)

      @client.delete("wf-#{wfid}.json.zlib")

      nil
    end

    def expression_wfids(opts)

      @client.list('wf-').collect { |fn| fn.split('.').first[3..-1] }
    end

    def purge!

      @client.purge
    end

    def get_many(type, key, opts)

      # TODO: :skip, :limit, :count, :descending

      opts[:execution_cache] ||= {}

      docs = []
      ewfids = nil

      wfids =
        if key
          key.collect { |i|
            if i.is_a?(Regexp)
              r = /^#{i.to_s[8..-7]}\b/
              (ewifds ||= expression_wfids(nil)).select { |id| id.match(r) }
            else
              i
            end
          }.flatten
        else
          expression_wfids(nil)
        end.uniq

      wfids.each do |wfid|

        exe = (opts[:execution_cache][wfid] ||= get_execution(wfid))
        docs.concat((exe[type] || {}).values)
      end

      docs
    end
  end
end

