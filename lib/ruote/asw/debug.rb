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


module Ruote::Asw

  module Debug

    def self.log_http(client, meth, uri, headers, body, res)

      return unless @@dlevel['ht'] > 0

      id = headers.object_id.to_s(16)[0, 4]

      t = now

      s = "        #{id} ht #{t} #{meth.upcase} #{uri.to_s}"
      s += " #{res.code} #{res.duration}s" if res
      puts(s)

      p res.body if res && res.code != 200
    end

    def self.log_swf(client, action, original_data, data, headers, res)

      return unless @@dlevel['sw'] > 0

      id = headers.object_id.to_s(16)[0, 4]

      t = now

      s = "        #{id} sw #{t} #{action}"
      s += " #{res.code} #{res.duration}s" if res
      puts(s)

      return unless @@dlevel['sw'] > 1

      #pp original_data
    end

    def self.parse_dlevel

      {
        'ht' => 0, 's3' => 0, 'sw' => 0
      }.merge(
        (ENV['RUOTE_ASW_DLEVEL'] || '').split(',').each_with_object({}) { |v, h|
          m = v.downcase.match(/^([a-z]+)(\d+)$/)
          next unless m
          target = m[1][0, 2]
          level = m[2].to_i
          if target == 'al' # all
            h.merge!('ht' => level, 's3' => level, 'sw' => level)
          elsif target
            h[target] = level
          end
        }
      )
    end

    @@dlevel = parse_dlevel

    def self.now

      Time.now.strftime('%R:%S.%3N')
    end

#    #--
#    # <ESC>[{attr1};...;{attrn}m
#    #
#    # 0 Reset all attributes
#    # 1 Bright
#    # 2 Dim
#    # 4 Underscore
#    # 5 Blink
#    # 7 Reverse
#    # 8 Hidden
#    #
#    # Foreground Colours
#    # 30 Black
#    # 31 Red
#    # 32 Green
#    # 33 Yellow
#    # 34 Blue
#    # 35 Magenta
#    # 36 Cyan
#    # 37 White
#    #
#    # Background Colours
#    # 40 Black
#    # 41 Red
#    # 42 Green
#    # 43 Yellow
#    # 44 Blue
#    # 45 Magenta
#    # 46 Cyan
#    # 47 White
#    #++
#
#    def color(mod, s, clear=false)
#
#      return s if Ruote::WIN
#      return s unless STDOUT.tty?
#
#      "[#{mod}m#{s}[0m#{clear ? '' : "[#{@color}m"}"
#    end
  end
end

