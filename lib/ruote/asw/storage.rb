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
require 'ruote/asw/swf_task'


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

      if bucket_or_store.is_a?(Hash)
        conf = bucket_or_store
        bucket_or_store = nil
      end

      @swf_client =
        SwfClient.new(self, aws_access_key_id, aws_secret_access_key)
      @swf_domain =
        domain

      @store =
        case bucket_or_store
          when String
            nil # TODO
          when :memory
            MemoryStore.new
          when nil
            nil # TODO
          else
            bucket_or_store
        end

      # TODO: rdoc me
      @preparation = nil
      @preparation = false if conf.delete(:no_preparation) == true
      @preparation = true if conf.delete(:prepare_immediately) == true

      replace_engine_configuration({
        'restless_worker' => true
      }.merge(conf))

      @decision_task_timeout = conf.delete('decision_task_timeout') || 10

      @workflow_name = 'ruote_asw_workflow'
      @activity_name = 'ruote_asw_activity'
      @version = '0.1'

      @decision_task_list = 'ruote_asw'
      @activity_task_list = 'ruote_asw'

      prepare if @preparation == true
    end

    #--
    # the methods a ruote storage must provide
    #++

    def reserve(doc)

      true
    end

    def get_msgs

      meth, task_list =
        if activity_worker?
          [ :poll_for_decision_task, @decision_task_list ]
        else
          [ :poll_for_activity_task, @activity_task_list ]
        end

      r = begin
        @swf_client.send(
          meth,
          'domain' => @swf_domain,
          'taskList' => { 'name' => task_list },
          'identity' => worker.identity)
      rescue Timeout::Error
        nil
      end

      set_task(r)

      task ? task.msgs : []
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

          @store.put_msg(msg)

          @swf_client.start_workflow_execution(
            'domain' => @swf_domain,
            'workflowId' => msg['wfid'],
            'workflowType' => {
              'name' => @workflow_name, 'version' => @version },
            'taskList' => { 'name' => @decision_task_list },
            'taskStartToCloseTimeout' => @decision_task_timeout.to_s)
            #'input' => bundle_id)

        else

          # TODO
          # BREAK IT ? IS THE ONLY SPECIAL CASE "LAUNCH" (A NEW WF EXECUTION) ?

          p [ action, options ]
      end
    end

    STORE_TYPES = %w[ configurations variables ]

    def put(doc, opts={})

      return @store.put(doc, opts) if STORE_TYPES.include?(doc['type'])

      task.put(doc)
    end

    def get(type, key)

      return @store.get(type, key) if STORE_TYPES.include?(type)

      p [ :get, type, key ]
    end

    def purge!

      @swf_client.purge!(@swf_domain)
      @store.purge!
    end

    #--
    # SWF preparation
    #++

    def prepare

      return if @preparation == false

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

    protected

    def decision_worker?

      ! activity_worker?
    end

    def activity_worker?

      !! worker.name.index('activity')
    end

    def set_task(res)

      Thread.current['ruote_asw_task'] = res ? SwfTask.new(@store, res) : nil
    end

    def task

      Thread.current['ruote_asw_task']
    end
  end
end

