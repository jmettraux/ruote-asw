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

require 'ruote/asw/http_client'


module Ruote::Asw

  class S3Client

    def initialize(aws_access_key_id, aws_secret_access_key, bucket)

      @aki = aws_access_key_id
      @sak = aws_secret_access_key
      @bucket = bucket

      raise ArgumentError.new(
        'invalid AWS access key and/or secret access key'
      ) unless (@aki && @sak)

      @http = HttpClient.new('ruote_asw_s3')

      # TODO: create bucket
    end

    def put(fname, content)

      request(:put, fname, content)
    end

    def get(fname)

      request(:get, fname)
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
    end

    def list

      r = request(:get, '')

      r.scan(/<Key>([^<]+)<\/Key>/).collect(&:first)
    end

    def purge

      l = list

      return if l.empty?

      delete(l)

      purge if l.size >= 1000
    end

    def self.create_bucket(aws_access_key_id, aws_secret_access_key, bucket)

      client = self.new(aws_access_key_id, aws_secret_access_key, bucket)
      client.send(:request, :put, '')
    end

    def self.delete_bucket(aws_access_key_id, aws_secret_access_key, bucket)

      client = self.new(aws_access_key_id, aws_secret_access_key, bucket)
      client.send(:request, :delete, '')
    end

    def self.list_buckets(aws_access_key_id, aws_secret_access_key)

      client = self.new(aws_access_key_id, aws_secret_access_key, nil)
      r = client.send(:request, :get, '')

      r.scan(/<Name>([^<]+)<\/Name>/).collect(&:first)
    end

    protected

    def request(meth, fname, body=nil)

      bucket = @bucket ? "#{@bucket}." : ''

      uri = URI.parse("https://#{bucket}s3.amazonaws.com/#{fname}")
      headers = {}

      sign(meth, uri, headers, body)

      r = @http.request(meth, uri, headers, body)

      if [ 200, 204 ].include?(r.code)
        meth == :get ? r.body : nil
      elsif [ 404 ].include?(r.code) && meth == :get
        nil
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

