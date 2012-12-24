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

require 'time'
require 'base64'
require 'openssl'
require 'net/http/persistent'

require 'ruote/util/misc'
require 'ruote/asw/version'


module Ruote::Asw

  class SwfClient

    DEFAULT_ENDPOINT = 'https://swf.us-east-1.amazonaws.com'

    def initialize(aws_access_key_id, aws_secret_access_key, opts={})

      @aki = aws_access_key_id
      @sak = aws_secret_access_key
      @opts = opts

      @endpoint = (opts['endpoint'] || DEFAULT_ENDPOINT).chomp('/')

      raise ArgumentError.new(
        'invalid AWS access key and/or secret access key'
      ) unless (@aki && @sak)

      @http = Net::HTTP::Persistent.new('asw')
      @http.read_timeout = opts['swf_read_timeout'] || 70
    end

    %w[

      list_domains

    ].each do |action|

      act = Ruote.camelize(action, true)

      class_eval(%{
        def #{action}(data={})
          request(#{act.inspect}, data)
        end
      }, __FILE__, __LINE__)
    end

    protected

    def request(action, data)

      original_data = data.dup
      data = data.inject({}) { |h, (k, v)| h[Ruote.camelize(k.to_s)] = v; h }
      body = Rufus::Json.encode(data)

      headers = {}

      headers['host'] = @endpoint.split('/').last

      headers['x-amz-date'] =
        Time.now.utc.httpdate
      headers['x-amz-target'] =
        "com.amazonaws.swf.service.model.SimpleWorkflowService.#{action}"
      headers['x-amzn-authorization'] =
        sign(headers, body)

      headers['date'] = headers['x-amz-date']
      headers['accept'] = 'application/json'
      headers['content-type'] = 'application/json; charset=UTF-8'
      headers['content-encoding'] = 'amz-1.0'

      uri = URI.parse(@endpoint + '/')

      req = Net::HTTP::Post.new(uri.path, headers)
      req.body = body

      r = @http.request(uri, req)

      Rufus::Json.decode(r.body)
    end

    # Amazon signature version 3.
    #
    def sign(headers, body)

      data =
        [
          'POST', '/', '',
          headers.to_a.collect { |k, v| "#{k.downcase}:#{v}\n" }.sort.join,
          body
        ].join("\n")

      sig =
        Base64.encode64(
          OpenSSL::HMAC.digest(
            OpenSSL::Digest.new('SHA256'),
            @sak,
            OpenSSL::Digest::SHA256.digest(data))).strip
      sigh =
        headers.keys.sort.join(';')

      [
        "AWS3 AWSAccessKeyId=#{@aki}",
        "Algorithm=HmacSHA256",
        "SignedHeaders=#{sigh}",
        "Signature=#{sig}"
      ].join(',')
    end
  end
end

