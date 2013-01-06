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

  def self.new_task(storage, res)

    if res.nil? || res['workflowExecution'].nil?

      OffTask.new(storage)

    elsif Ruote.current_worker.name.index('activity')

      ActivityTask.new(storage, res)

    else

      DecisionTask.new(storage, res)
    end
  end

  #
  # The root class for all tasks.
  #
  class Task

    def initialize(storage)

      @storage = storage

      @system = @storage.store.load_system
    end

    def get(type, key)

      @system[type][key]
    end

    def put(doc, opts={})

      @storage.store.put(doc, opts)

      nil
    end

    def any_msg?

      false
    end

    def get_schedules(delta, now)

      []
    end

    def expression_wfids(opts={})

      @storage.store.expression_wfids(opts)
    end

    protected

    def system_doc?(doc)

      system_type?(doc['type'])
    end

    def system_type?(type)

      Ruote::Asw::Storage::SYSTEM_TYPES.include?(type)
    end

    def prepare_msg(action, options, fulldup=false)

      msg = fulldup ? Ruote.fulldup(options) : options.dup
      pa = Ruote.now_to_utc_s

      id =
        [
          action,
          options['fei'] ? Ruote.sid(options['fei']) : options['wfid'],
          pa.gsub(/[ :\.]/, '-')[0..-5]
        ].compact.join('_')

      msg['wfid'] ||= msg['fei']['wfid'] if msg['fei']

      msg.merge!('_id' => id, 'action' => action, 'put_at'=> pa)
    end
  end

  #
  # The task class used for "off tasks", when an action has to be taken
  # outside of a decision / activity task.
  #
  class OffTask < Task

    def put_msg(action, options)

      msg = prepare_msg(action, options)

      return launch(msg) if action == 'launch' && msg.has_key?('stash')

      signal(msg)
    end

    def get_many(type, key=nil, opts={})

      @storage.store.get_many(type, key, opts)
    end

    protected

    def launch(msg)

      @storage.store.put_msg(msg)

      @storage.swf_client.start_workflow_execution(
        'domain' => @storage.swf_domain,
        'workflowId' => msg['wfid'],
        'workflowType' => {
          'name' => @storage.workflow_name, 'version' => @storage.wa_version },
        'taskList' => { 'name' => @storage.decision_task_list },
        'taskStartToCloseTimeout' => @storage.decision_task_timeout.to_s)
        #'input' => bundle_id)
    end

    MINOR_ACTIONS = %w[ participant_registered ]

    def signal(msg)

      return if MINOR_ACTIONS.include?(msg['action'])

      puts "--->SIGNAL>>> #{self.class}"
      p msg
      puts caller
      puts '---<<<SIGNAL<'
    end
  end

  #
  # The parent class for decision and activity tasks.
  #
  class SwfTask < Task

    attr_reader :wfid
    attr_reader :task_token

    def initialize(storage, res)

      super(storage)

      @res = res

      @wfid = res['workflowExecution']['workflowId']
      @task_token = res['taskToken']

      @execution =
        @storage.store.get_execution(@wfid) ||
        { 'expressions' => {}, 'errors' => {} }

    #rescue => e
    #  puts '>' + '-' * 79
    #  p e
    #  pp res
    #  puts '<' + '-' * 79
    #  raise e
    end

    def any_msg?

      @msgs.any?
    end

    def fetch_msgs

      r = @msgs.dup
      @msgs.clear

      r
    end

    def reserve(doc)

      true
    end

    def get(type, key)

      return super if system_type?(type)

      @execution[type][key]
    end

    def put(doc, opts={})

      return super if system_doc?(doc)

      @execution[doc['type']][doc['_id']] = doc

      nil
    end

    def delete(doc, opts={})

      return super if system_doc?(doc)

      @execution[doc['type']].delete(doc['_id'])

      nil
    end
  end

  #
  # Wraps an SWF decision task.
  #
  class DecisionTask < SwfTask

    def initialize(storage, res)

      super

      @store_msgs = @storage.store.get_msgs(@wfid)
      @msgs = @store_msgs.dup

      @activities = []
    end

    def done(msg)

      return if any_msg?

      # TODO: complete me!

      decisions = []

      if execution_over?

        decisions << {
          'decisionType' => 'CompleteWorkflowExecution',
          #'completeWorkflowExecutionAttributes' => { 'result' => msg } }
          'completeWorkflowExecutionAttributes' => {} }

      else

        @activities.each do |msg|

          @storage.store.put_msg(msg)

          decisions << {
            'decisionType' => 'ScheduleActivityTask',
            'scheduleActivityTaskDecisionAttributes' => {
              'activityType' => {
                'name' => @storage.activity_name,
                'version' => @storage.wa_version },
              'activityId' => activity_id(msg),
              'control' => msg['_id'],
              'taskList' => { 'name' => @storage.activity_task_list } } }
              #'input' => msg['_id'],
              #'heartbeatTimeout' => 'NONE' } }
              #'scheduleToCloseTimeout' => 'NONE',
              #'scheduleToStartTimeout' => 'NONE',
              #'startToCloseTimeout' => 'NONE',

          # TODO: implement round-robin on activity task list for fairness...
        end

      end

      @storage.swf_client.respond_decision_task_completed(
        'taskToken' => task_token,
        'decisions' => decisions)

      @storage.store.del_msgs(@store_msgs)

      @storage.context.notify(
        'action' => 'decision_done',
        'fei' => msg['fei'],
        'wfid' => msg['wfid'],
        'put_at' => Ruote.now_to_utc_s)

      if execution_over?
        @storage.store.del_execution(wfid)
      else
        @storage.store.put_execution(wfid, @execution)
      end
    end

    def put_msg(action, options)

      msg = prepare_msg(action, options, true)

      if action.match(/^dispatch/)

        @activities << msg

      else

        @msgs << msg
      end


      nil
    end

    protected

    def execution_over?

      @execution['expressions'].empty?
    end

    def activity_id(msg)
      [
        case msg['action']
          when 'dispatch' then 'd'
          when 'dispatch_cancel' then 'dc'
          else msg['action']
        end,
        msg['fei']['wfid'],
        msg['fei']['expid'],
        msg['fei']['subid']
      ].join('!')[0, 256]
    end
  end

  #
  # Wraps an SWF activity task.
  #
  class ActivityTask < SwfTask

    def initialize(storage, res)

      super

      @store_msgs = @storage.store.get_activity_msgs(@wfid)
      @msgs = @store_msgs.dup
    end

    FINAL_ACTIONS = %w[ receive error_intercepted ]

    def put_msg(action, options)

      msg = prepare_msg(action, options)

      if FINAL_ACTIONS.include?(action)

        @storage.store.put_msg(msg)

        @storage.swf_client.respond_activity_task_completed(
          'taskToken' => task_token,
          'result' => action)

      else

        # TODO: deal with out of band messages, signal???

        @msgs << msg
      end
    end

    def done(msg)

      # nothing to do, the 'receive' action responded to SWF.
    end
  end
end

