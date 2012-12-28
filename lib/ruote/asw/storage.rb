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

require 'ruote/asw/swf_client'


module Ruote::Asw

  class Storage
    include Ruote::StorageBase

    def initialize(
      aws_access_key_id,
      aws_secret_access_key,
      domain,
      bucket_or_store
    )

      @swf_client =
        SwfClient.new(self, aws_access_key_id, aws_secret_access_key)
      @swf_domain =
        domain

      @store =
        if bucket_or_store.is_a?(String)
          # TODO
        elsif bucket_or_store == :memory
          MemoryStore.new
        else
          bucket_or_store
        end

      # TODO: try register domain
    end

    #--
    # the methods a ruote storage must provide
    #++

    def get_msgs

      []
    end

    def get_schedules(delta, now)

      []
    end

    def put_msg(action, options)

      msg = options.merge('action' => action)
      msg['put_at'] = Ruote.now_to_utc_s

      action = 'apply' if action == 'launch' && ( ! options.has_key?('stash'))
        #
        # sub-processes (sub-launches) are running inside of the same
        # SWF workflow execution

      case action
        when 'launch', 'relaunch'
          bundle_id = @store.put('wfid' => msg['wfid'], 'msgs' => [ msg ])
          p :start_workflow_execution__!
        else
          p [ action, options ]
      end
    end

    def get(type, key)

      return @store.get(type, key) if type == 'configurations'

      p [ type, key ]
    end

    #--
    # other methods
    #++

    def prepare

      puts "~~~~~~~~~~~~~~~~~~~~~~~ prepare!"
    end
  end
end

