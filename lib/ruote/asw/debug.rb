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

require 'yaml'
require 'ruote/util/misc'


module Ruote::Asw

  module Debug

    @@next_drip = '|....'

    # Log HTTP requests (and responses).
    #
    def self.log_http(client, meth, uri, headers, body, res_or_err)

      return unless @@dlevel['ht'] > 0

      res, err = [ res_or_err, nil ]
      res, err = err, res if res.is_a?(Exception)

      id = request_id(headers)

      t = now
      prefix = "        #{worker} #{id}  ht #{t}"

      s = "#{prefix} #{meth.upcase} #{uri.to_s}"
      if res
        s += " #{res.code} #{res.duration}s"
      elsif err
        s += " err #{err.class}: #{err.message} #{err.duration}s"
      end

      echo(s)

      return unless @@dlevel['ht'] > 1

      echo(res.body) if res && res.code != 200
    end

    # Log SWF requests (and responses).
    #
    def self.log_swf(client, action, original_data, data, headers, res)

      return unless @@dlevel['sw'] > 0

      id = request_id(headers)

      t = now
      prefix = "        #{worker} #{id} sw  #{t}"

      s = "#{prefix} #{action}"
      s += " #{res.code} #{res.duration}s" if res
      echo(s)

      return unless @@dlevel['sw'] > 1

      j = res && res.from_json
      info = j && j['workflowException']
      echo("#{prefix} #{action} #{Ruote.insp(info)}") if info

      return unless @@dlevel['sw'] > 2

      if res.nil?

        #echo("#{prefix} #{Ruote.insp(data)}")
        echo("#{prefix} to swf:")
        YAML.dump(data).split("\n")[1..-1].each do |l|
          echo("#{prefix}   #{l}")
        end

      else

        res.from_json['executionInfos'].each do |ei|
          ex = ei['execution']
          echo("#{prefix}   wi #{ex['workflowId']} ri #{ex['runId']}")
        end if action == 'ListOpenWorkflowExecutions'
      end

      return unless @@dlevel['sw'] > 3

      if res

        echo("#{prefix} from swf:")
        YAML.dump(res.from_json).split("\n")[1..-1].each do |l|
          echo("#{prefix}   #{l}")
        end
      end
    end

    def self.request_id(headers)

      if headers.respond_to?(:_drip)
        d = headers._drip
        @@next_drip = d[-1] + d[0..-2]
      else
        class << headers; attr_accessor :_drip; end
        headers._drip = @@next_drip
      end

      headers.object_id.to_s(16)[0, 4] + headers._drip
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

    def self.worker

      Thread.current['ruote_worker'].class.name.split('::').last.downcase[0, 3]
    end

    def self.echo(s)

      col =
        case Ruote.current_worker
          when Ruote::Asw::DecisionWorker then '36;2'
          when Ruote::Asw::ActivityWorker then '32;2'
          else '34;2' # blue
        end

      #$stdout.puts(colour(col, s[0..11]) + s[12..-1])
      $stdout.puts(colour(col, s))
    end

    def self.colour(mod, s, clear=false)

      return s if Ruote::WIN
      return s unless $stdout.tty?

      "[#{mod}m#{s}[0m"
    end

    #--
    # <ESC>[{attr1};...;{attrn}m
    #
    # 0 Reset all attributes
    # 1 Bright
    # 2 Dim
    # 4 Underscore
    # 5 Blink
    # 7 Reverse
    # 8 Hidden
    #
    # Foreground Colours
    # 30 Black
    # 31 Red
    # 32 Green
    # 33 Yellow
    # 34 Blue
    # 35 Magenta
    # 36 Cyan
    # 37 White
    #
    # Background Colours
    # 40 Black
    # 41 Red
    # 42 Green
    # 43 Yellow
    # 44 Blue
    # 45 Magenta
    # 46 Cyan
    # 47 White
    #++
  end
end

