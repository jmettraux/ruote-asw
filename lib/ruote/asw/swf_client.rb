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

require 'ruote/util/misc'
require 'ruote/asw/http_client'


module Ruote::Asw

  class SwfClient

    DEFAULT_ENDPOINT = 'https://swf.us-east-1.amazonaws.com'

    attr_reader :owner

    def initialize(owner, aws_access_key_id, aws_secret_access_key, opts={})

      @owner = owner
      @aki = aws_access_key_id
      @sak = aws_secret_access_key
      @opts = opts

      endpoint = (opts['endpoint'] || DEFAULT_ENDPOINT).chomp('/')
      @uri = URI.parse(endpoint + '/')
      @host = endpoint.split('/').last

      raise ArgumentError.new(
        'invalid AWS access key and/or secret access key'
      ) unless (@aki && @sak)

      @http = HttpClient.new('ruote_asw_swf')
      @http.read_timeout = opts['swf_read_timeout'] || 70

      @first_request = true
    end

    %w[

      list_domains
      list_activity_types
      list_workflow_types
      list_open_workflow_executions
      register_domain
      register_activity_type
      register_workflow_type
      start_workflow_execution
      terminate_workflow_execution

    ].each do |action|

      act = Ruote.camelize(action, true)

      class_eval(%{
        def #{action}(data={})
          request(#{act.inspect}, data)
        end
      }, __FILE__, __LINE__)
    end

    def open_executions(domain)

      list_open_workflow_executions(
        :domain => domain,
        :startTimeFilter => {
          'oldestDate' => Time.now.to_i - 2 * 365 * 24 * 3600,
          'latestDate' => Time.now.to_i },
        :reverseOrder => true
      )['executionInfos']
    end

    def purge!(domain)

      open_executions(domain).collect do |ei|

        terminate_workflow_execution(
          'domain' => domain,
          'workflowId' => ei['execution']['workflowId'])

        ei['execution']
      end
    end

    protected

    def request(action, data)

      if @first_request
        @first_request = false
        @owner.prepare if @owner.respond_to?(:prepare)
      end

      original_data = data.dup
      data = data.inject({}) { |h, (k, v)| h[Ruote.camelize(k.to_s)] = v; h }
      body = Rufus::Json.encode(data)

      headers = {}

      headers['host'] = @host

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

      log(action, original_data, data, headers)

      res = Response.new(@http.request(:post, @uri, headers, body))

      log(action, original_data, data, headers, res)

      raise res.error if res.error

      res.from_json
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

    def log(action, original_data, data, headers, res=nil)

      Debug.log_swf(self, action, original_data, data, headers, res)
    end

    class Response

      attr_reader :error

      def initialize(http_res)

        @http_res = http_res

        @error = code != 200 ? Ruote::Asw::SwfClient::Error.new(self) : nil
      end

      def method_missing(m, *args)

        return @http_res.send(m, *args) if @http_res.respond_to?(m)

        super
      end
    end

    class Error < StandardError

      def initialize(res)

        @res = res

        super(res.from_json['__type'].split('#').last)
      end
    end
  end
end

