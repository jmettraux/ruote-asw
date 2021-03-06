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

require 'ruote/asw/version'
require 'ruote/asw/debug'
require 'ruote/asw/clients/geo'


module Ruote::Asw

  class HttpClient

    attr_reader :name
    attr_reader :last_request

    def initialize(name)

      @name = name
      @http = Net::HTTP::Persistent.new(name)
      @last_request = nil
    end

    def read_timeout=(seconds)

      @http.read_timeout = seconds
    end

    def open_timeout=(seconds)

      @http.open_timeout = seconds
    end

    def request(meth, uri, headers, body)

      t = nil

      kla =
        case meth
          when :put then Net::HTTP::Put
          when :post then Net::HTTP::Post
          when :delete then Net::HTTP::Delete
          else Net::HTTP::Get
        end

      uri = URI.parse(uri) unless uri.is_a?(URI)
      path = [ uri.path, uri.query ].compact.join('?')

      req = kla.new(path, headers)
      req.body = body if body

      t = Time.now
      log(meth, uri, headers, body)

      res = Response.new(@http.request(uri, req), t)

      log(meth, uri, headers, body, res)

      res

    rescue Exception => e
      #
      # catch anything, log, then re-raise

      p e
      puts e.backtrace

      class << e; attr_accessor :duration; end
      e.duration = t ? Time.now - t : 0

      log(meth, uri, headers, body, e)

      raise e
    end

    def log(meth, uri, headers, body, res=nil)

      @last_request =
        { :meth => meth,
          :uri => uri,
          :headers => headers,
          :body => body,
          :res => res.respond_to?(:to_h) ? res.to_h : res }

      Debug.log_http(self, meth, uri, headers, body, res)
    end

    class Response

      attr_reader :start, :duration
      attr_accessor :content # for 304s

      def initialize(res, start)

        @res = res
        @start = start
        @duration = Time.now - start
      end

      def code

        @res.code.to_i
      end

      def headers

        @headers ||=
          begin
            h = {}; @res.each_header { |k, v| h[k] = v }; h
          end
      end

      def body

        @res.body
      end

      def from_json

        Rufus::Json.decode(@res.body)
      end

      def error_message

        # for now only deals with S3 (XML) errors

        return body unless body.index('<Error>')

        code = body.match(/<Code>([^<]+)<\/Code>/)[1]
        message = body.match(/<Message>([^<]+)<\/Message>/)[1]

        "#{code}: #{message}"
      end

      def to_h

        {
          :code => code,
          :headers => headers,
          :start => start,
          :duration => duration,
          :body => body,
          :error => !! (body || '').index('<Error>')
        }
      end
    end
  end
end

