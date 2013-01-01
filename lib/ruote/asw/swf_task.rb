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

  class SwfTask

    attr_reader :wfid, :task_token

    def initialize(store, res)

      @wfid = res['workflowExecution']['workflowId']
      @task_token = res['taskToken']

      @msgs = store.get_msgs(@wfid)
      #@docs = store.get_data(@wfid)
      @docs = {}
    end

    def put(doc)

      (@docs[doc['type']] ||= {})[doc['_id']] = doc

      nil # success
    end

    def get(type, key)

      (@docs[type] || {})[key]
    end

    def delete(doc)

      @docs[doc['type']].delete(doc['_id'])

      nil # success
    end

    def any_msg?

      @msgs.any?
    end

    def fetch_msgs

      r = @msgs.dup
      @msgs.clear

      r
    end

    def put_msg(msg)

      #@msgs << msg
      @msgs << Ruote.fulldup(msg)

      nil
    end
  end
end
