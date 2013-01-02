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
      @executions = {}
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

    def get_many(type, key, opts)

      # TODO: :skip, :limit, :count, :descending

      docs =
        @executions.values.collect { |e|
          (e[type] || {}).values
        }.flatten(1)

      if key
        keys = Array(key).map { |k| k.is_a?(String) ? "!#{k}" : k }
        docs.select { |doc| Ruote::StorageBase.key_match?(keys, doc) }
      else
        docs
      end
    end

    def expression_wfids(opts)

      @executions.keys.sort
    end

    def put_execution(wfid, execution)

      @executions[wfid] = execution

      nil
    end

    def get_execution(wfid)

      @executions[wfid]
    end

    def del_execution(wfid)

      @executions.delete(wfid)

      nil
    end

    def purge!

      # TODO
    end
  end
end

