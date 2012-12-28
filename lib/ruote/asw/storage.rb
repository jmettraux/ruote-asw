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
      bucket_or_store,
      conf={}
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

      replace_engine_configuration({
        'restless_worker' => true
      }.merge(conf))

      @decision_task_timeout = conf.delete('decision_task_timeout') || 10

      @workflow_name = 'ruote_asw_workflow'
      @activity_name = 'ruote_asw_activity'
      @version = '0.1'

      @decision_task_list = 'ruote_asw'
      @activity_task_list = 'ruote_asw'
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

          bundle_id =
            @store.put_bundle('wfid' => msg['wfid'], 'msgs' => [ msg ])

          @swf_client.start_workflow_execution(
            'domain' => @swf_domain,
            'workflowId' => msg['wfid'],
            'workflowType' => {
              'name' => @workflow_name, 'version' => @version },
            'taskList' => { 'name' => @decision_task_list },
            'taskStartToCloseTimeout' => @decision_task_timeout.to_s,
            'input' => bundle_id)

        else

          p [ action, options ]
      end
    end

    def put(doc)

      return @store.put(doc) if doc['type'] == 'configurations'

      p doc
    end

    def get(type, key)

      return @store.get(type, key) if type == 'configurations'

      p [ type, key ]
    end

    #--
    # SWF preparation
    #++

    def prepare

      prepare_domain
      prepare_workflow_type
      prepare_activity_type
    end

    def prepare_domain

      @swf_client.register_domain(
        'name' => @swf_domain,
        'workflowExecutionRetentionPeriodInDays' => '90')
          # 90 days is the max :-(

    rescue Ruote::Asw::SwfClient::Error => sce

      raise sce unless sce.message.match(/DomainAlreadyExistsFault/)
    end

    def prepare_workflow_type

      @swf_client.register_workflow_type(
        'domain' => @swf_domain,
        'name' => @workflow_name,
        'version' => @version,
        'defaultChildPolicy' => 'TERMINATE',
        'defaultExecutionStartToCloseTimeout' => (365 * 24 * 3600).to_s,
          # 1 year max (the default)
        'defaultTaskList' => { 'name' => @decision_task_list },
        'defaultTaskStartToCloseTimeout' => 30.to_s)
          # 30 seconds max

    rescue Ruote::Asw::SwfClient::Error => sce

      raise sce unless sce.message.match(/TypeAlreadyExistsFault/)
    end

    def prepare_activity_type

      # TODO: consider heartbeat...

      @swf_client.register_activity_type(
        'domain' => @swf_domain,
        'name' => @activity_name,
        'version' => @version,
        'defaultTaskList' => { 'name' => @activity_task_list },
        'defaultTaskHeartbeatTimeout' => 'NONE',
        'defaultTaskScheduleToCloseTimeout' => 'NONE',
        'defaultTaskScheduleToStartTimeout' => 'NONE',
        'defaultTaskStartToCloseTimeout' => 'NONE')

    rescue Ruote::Asw::SwfClient::Error => sce

      raise sce unless sce.message.match(/TypeAlreadyExistsFault/)
    end
  end
end

