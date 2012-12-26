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


module Ruote::Asw

  module Debug

    def self.log(client, meth, uri, headers, body, res)

      return unless dlevel['ht'] > 0

      t = Time.now.strftime('%R:%S.%3N')

      s = "        #{t} #{meth.upcase} #{uri.to_s}"
      s += " #{res.code} #{res.duration}s" if res
      puts(s)
    end

    def self.dlevel

      {
        'ht' => 0, 's3' => 0, 'sw' => 0
      }.merge(
        (ENV['RUOTE_ASW_DLEVEL'] || '').split(',').inject({}) { |h, v|
          m = v.match(/^([a-z]+)(\d+)$/)
          h[m[1][0, 2]] = m[2].to_i if m
          h
        }
      )
    end
  end
end

