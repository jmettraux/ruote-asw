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


module Ruote::Asw

  class HttpClient

    def initialize(name)

      @http = Net::HTTP::Persistent.new(name)
    end

    def read_timeout=(seconds)

      @http.read_timeout = seconds
    end

    def request(meth, uri, headers, body)

      kla =
        case meth
          when :put then Net::HTTP::Put
          when :post then Net::HTTP::Post
          when :delete then Net::HTTP::Delete
          else Net::HTTP::Get
        end

      uri = URI.parse(uri) unless uri.is_a?(URI)

      req = kla.new(uri.path, headers)
      req.body = body if body

      Response.new(@http.request(uri, req))
    end

    class Response

      def initialize(res)

        @res = res
      end

      def code

        @res.code.to_i
      end

      def body

        @res.body
      end

      def from_json

        Rufus::Json.decode(@res.body)
      end
    end
  end
end
