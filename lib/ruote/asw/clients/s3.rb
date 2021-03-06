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

require 'cgi'
require 'zlib'

require 'rufus-lru'
require 'ruote/asw/clients/http'


module Ruote::Asw

  class S3Client

    attr_reader :owner, :cache

    def initialize(
      owner,
      access_key_id,
      secret_access_key,
      bucket,
      opts={}
    )

      @owner = owner
      @aki = access_key_id
      @sak = secret_access_key
      @bucket = bucket
      @opts = opts

      raise ArgumentError.new(
        'invalid AWS access key and/or secret access key'
      ) unless (@aki && @sak)

      @endpoint = 's3'

      @http = HttpClient.new('ruote_asw_s3')

      if r = @opts[:region]
        self.class.create_bucket(@aki, @sak, bucket, r, true)
      end

      @cache = Rufus::Lru::Hash.new(35)
    end

    def last_request

      @http.last_request
    end

    def put(fname, content)

      split = fname.split('.')

      con = content
      con = Rufus::Json.encode(content) if split.include?('json')

      #Zlib::BEST_COMPRESSION
      #Zlib::BEST_SPEED
      #Zlib::DEFAULT_COMPRESSION
        #
        # go for best_compression for now

      con =
        Zlib::Deflate.deflate(
          con, Zlib::BEST_COMPRESSION
        ) if split.last == 'zlib'

      res = request(:put, fname, con)

      do_cache(fname, content, res)

      nil
    end

    def get(fname)

      split = fname.split('.')

      res = request(:get, fname)

      return nil if res.code == 404
      return res.content if res.code == 304

      content = res.body

      content = Zlib::Inflate.inflate(content) if split.last == 'zlib'
      content = Rufus::Json.decode(content) if split.include?('json')

      do_cache(fname, content, res)

      content
    end

    def delete(fname_s)

      if fname_s.is_a?(Array)

        d = []
        d << '<?xml version="1.0" encoding="UTF-8"?>'
        #d << '<Quiet>true</Quiet>'
        d << '<Delete>'
        fname_s.each { |n| d << "<Object><Key>#{n}</Key></Object>" }
        d << '</Delete>'
        d = d.join("\n")

        request(:post, '?delete', d)

      else

        request(:delete, fname_s)
      end

      Array(fname_s).each { |n| @cache.delete(n) }

      nil
    end

    LIST_MAX_KEYS = 1000

    def list(prefix=nil, marker=nil, max=LIST_MAX_KEYS)

      # see http://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketGET.html

      path = "?max-keys=#{max}"
      path = "#{path}&prefix=#{CGI.escape(prefix)}" if prefix
      path = "#{path}&marker=#{CGI.escape(marker)}" if marker

      r = request(:get, path)

      raise ArgumentError.new(
        "bucket '#{@bucket}' doesn't seem to exist"
      ) if r.code == 404

      fnames = r.body.scan(/<Key>([^<]+)<\/Key>/).collect(&:first)

      if fnames.size >= max && r.body.index('<IsTruncated>true</IsTruncated>')
        fnames + list(prefix, fnames[-1], max)
      else
        fnames
      end
    end

    def purge(prefix=nil)

      list(prefix).each_slice(LIST_MAX_KEYS) { |s| delete(s) }
    end

    #--
    # bucket listing, creation/deletion
    #++

    def self.create_bucket(
      access_key_id, secret_access_key, bucket, region, quiet=false
    )

      reg = Ruote::Asw.lookup_s3_region(region)

      doc = []
      doc << '<?xml version="1.0" encoding="UTF-8"?>'
      doc << '<CreateBucketConfiguration'
      doc << ' xmlns="http://s3.amazonaws.com/doc/2006-03-01/">'
      doc << "<LocationConstraint>#{reg}</LocationConstraint>"
      doc << '</CreateBucketConfiguration>'
      doc = doc.join("\n")

      client = self.new(nil, access_key_id, secret_access_key, nil)

      begin
        client.send(:request, :put, bucket, doc)
        nil
      rescue ArgumentError => ae
        raise ae unless quiet && ae.message.match(/^BucketAlreadyOwnedByYou:/)
        nil
      end
    end

    def self.delete_bucket(
      access_key_id, secret_access_key, bucket, force=false
    )

      client = self.new(nil, access_key_id, secret_access_key, bucket)

      client.purge if force
      client.send(:request, :delete, '')
    end

    def self.list_buckets(access_key_id, secret_access_key)

      client = self.new(nil, access_key_id, secret_access_key, nil)
      r = client.send(:request, :get, '')

      r.body.scan(/<Name>([^<]+)<\/Name>/).collect(&:first)
    end

    protected

    def do_cache(fname, content, res)

      return unless res.code == 200
      return if @opts[:no_cache]

      etag = res.headers['etag']
      return unless etag

      @cache[fname] = [ etag, content ]
    end

    def request(meth, fname, body=nil)

      bucket = @bucket ? "#{@bucket}." : ''

      uri = URI.parse("https://#{bucket}#{@endpoint}.amazonaws.com/#{fname}")
      headers = {}

      etag, content = meth == :get ? @cache[fname] : nil
      headers['if-none-match'] = etag if etag

      sign(meth, uri, headers, body)

      r = @http.request(meth, uri, headers, body)

      r.content = content if r.code == 304

      if r.code == 307
        #
        # support for redirections
        # most likely only helps .create_bucket and .delete_bucket

        @endpoint =
          r.body.match(/<Endpoint>([^<]+)<\/Endpoint>/)[1].split('.')[1]

        request(meth, fname, body)

      elsif r.code >= 400 && r.code != 404 && r.code < 500

        fail ArgumentError.new(r.error_message)

      else

        r
      end
    end

    def sign(meth, uri, headers, body)

      headers['date'] ||= Time.now.rfc822

      if body

        headers['content-type'] =
          if body.match(/^<\?xml/)
            #'multipart/form-data'
            'application/xml'
          else
            'text/plain'
          end
        #headers['content-type'] = 'text/plain' unless body.match(/^<\?xml/)

        headers['content-md5'] =
          Base64.encode64(Digest::MD5.digest(body)).strip
      end

      headers['authorization'] =
        [
          "AWS #{@aki}",
          Base64.encode64(
            OpenSSL::HMAC.digest(
              OpenSSL::Digest.new('SHA1'),
              @sak,
              string_to_sign(meth, uri, headers)
            )
          ).strip
        ].join(':')
    end

    def canonicalized_amz_headers(headers)

      s = headers.select { |k, v|
        k.match(/^x-amz-/i)
      }.collect { |k, v|
        [ k.downcase, v ]
      }.sort_by { |k, v|
        k
      }.collect { |k, v|
        "#{k}:#{v}"
      }.join("\n")

      s == '' ? nil : s
    end

    #S3_PARAMS =
    #  %w[
    #    acl location logging notification partNumber policy
    #    requestPayment torrent uploadId uploads versionId
    #    versioning versions delete lifecycle
    #  ] +
    #  %w[
    #    response-content-type response-content-language
    #    response-expires response-cache-control
    #    response-content-disposition response-content-encoding
    #  ]

    def canonicalized_resource(uri)

      r = []
      r << "/#{@bucket}" if @bucket
      r << uri.path

      #q = query_string.select { |k, v|
      #  S3_PARAMS.include?(k)
      #}.to_a.sort_by { |k, v|
      #  k
      #}.collect { |k, v|
      #  "#{k}=#{v}"
      #}
      #r << '?' + q.join('&') if q.any?

      r << '?delete' if uri.query == 'delete'

      r.join
    end

    def string_to_sign(meth, uri, headers)

      hs = canonicalized_amz_headers(headers)

      a = []
      a << meth.to_s.upcase
      a << headers['content-md5']
      a << headers['content-type']
      a << headers['date']
      a << hs if hs
      a << canonicalized_resource(uri)

      a.join("\n")
    end
  end
end

