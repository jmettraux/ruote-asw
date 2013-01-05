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
require 'ruote/asw/tasks'


module Ruote::Asw

  class Storage
    include Ruote::StorageBase

    SYSTEM_TYPES = %w[ configurations variables ]

    attr_reader :swf_client, :store

    attr_reader :swf_domain
    attr_reader :workflow_name
    attr_reader :activity_name
    attr_reader :wa_version
    attr_reader :decision_task_list
    attr_reader :activity_task_list
    attr_reader :decision_task_timeout

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
        'restless_worker' => true,
          # not polling workers, no need to rest between polls...
        'participant_threads_enabled' => false
          # disabled 1 dispatch 1 thread...
      }.merge(conf))

      @decision_task_timeout = conf.delete('decision_task_timeout') || 10

      @workflow_name = 'ruote_asw_workflow'
      @activity_name = 'ruote_asw_activity'
      @wa_version = '0.1'

      @decision_task_list = 'ruote_asw'
      @activity_task_list = 'ruote_asw'

      prepare if @preparation == true
    end

    #--
    # the methods a ruote storage must provide
    #++

    %w[

      delete
      done
      expression_wfids
      get_schedules
      get_many
      get
      put
      put_msg
      reserve

    ].each do |m|

      class_eval(%{
        def #{m}(*args); task.#{m}(*args); end
      }, __FILE__, __LINE__)
    end

    def get_msgs

      # TODO: implement multi-tasklist system for activities

      return task.fetch_msgs if task && task.any_msg?

      meth, task_list =
        if worker.name.index('activity')
          [ :poll_for_activity_task, @activity_task_list ]
        else
          [ :poll_for_decision_task, @decision_task_list ]
        end

      r = begin
        @swf_client.send(
          meth,
          'domain' => @swf_domain,
          'taskList' => { 'name' => task_list },
          'identity' => worker.identity)
      #rescue Timeout::Error
      #  nil
      end

      set_task(r)

      []
    end

    def purge!

      @swf_client.purge!(@swf_domain)
      @store.purge!
    end

    #--
    # extra methods
    #++

    def open_executions

      @swf_client.open_executions(@swf_domain)
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

    protected

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
        'version' => @wa_version,
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
        'version' => @wa_version,
        'defaultTaskList' => { 'name' => @activity_task_list },
        'defaultTaskHeartbeatTimeout' => 'NONE',
        'defaultTaskScheduleToCloseTimeout' => 'NONE',
        'defaultTaskScheduleToStartTimeout' => 'NONE',
        'defaultTaskStartToCloseTimeout' => 'NONE')

    rescue Ruote::Asw::SwfClient::Error => sce

      raise sce unless sce.message.match(/TypeAlreadyExistsFault/)
    end

    def set_task(res)

      Thread.current['ruote_asw_task'] = Ruote::Asw.new_task(self, res)
    end

    def task

      Thread.current['ruote_asw_task'] || Ruote::Asw.new_task(self, nil)
    end
  end
end

