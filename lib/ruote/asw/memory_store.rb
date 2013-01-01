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

  class MemoryStore

    def initialize

      @system = {
        'configurations' => { 'engine' => {} },
        'variables' => {}
      }
      @states = {}
      @msgs = []
    end

    def load_system

      @system
    end

    def put(doc, opts)

      @system[doc['type']][doc['_id']] = doc
    end

    def put_msg(msg)

      @msgs << msg
    end

    def get_msgs(wfid)

      @msgs.select { |m| m['wfid'] == wfid }
    end

#    def purge(wfid)
#
#      @data.delete(wfid)
#    end
#
#    def del_msg(msg)
#
#      msg_id = msg['_id']
#
#      @msgs.delete_if { |m| m['_id'] == msg_id }
#    end
#
#    def expression_wfids(opts)
#
#      @data.keys.sort
#    end

    def purge!

      # TODO
    end
  end
end

