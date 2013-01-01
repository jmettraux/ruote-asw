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

    if res.nil?

      OffTask.new(storage)

    elsif Ruote.current_worker.name.index('activity')

      ActivityTask.new(storage, res)

    else

      DecisionTask.new(storage, res)
    end
  end

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

    protected

    SYSTEM_TYPES = %w[ configurations variables ]

    def system_doc?(doc)

      system_type?(doc['type'])
    end

    def system_type?(type)

      SYSTEM_TYPES.include?(type)
    end
  end

  class OffTask < Task

    def put_msg(action, options)

      msg = options.merge('action' => action, 'put_at'=> Ruote.now_to_utc_s)

      return launch(msg) if action == 'launch' && msg.has_key?('stash')

      signal(msg)
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
  end

  class SwfTask < Task

    attr_reader :wfid
    attr_reader :task_token

    def initialize(storage, res)

      super(storage)

      @res = res

      @wfid = res['workflowExecution']['workflowId']
      @task_token = res['taskToken']

      @store_msgs = @storage.store.get_msgs(@wfid)
      @msgs = @store_msgs.dup

      @state = {
        'expressions' => {}, 'errors' => {}
      }
    end

    def any_msg?

      @msgs.any?
    end

    def put_msg(action, options)

      @msgs <<
        Ruote.fulldup(options.merge(
          'action' => action, 'put_at'=> Ruote.now_to_utc_s))

      nil
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

      @state[type][key]
    end

    def put(doc, opts={})

      return super if system_doc?(doc)

      @state[doc['type']][doc['_id']] = doc

      nil
    end

    def delete(doc, opts={})

      return super if system_doc?(doc)

      @state[doc['type']].delete(doc['_id'])

      nil
    end
  end

  class DecisionTask < SwfTask

    def done(msg)

      return if any_msg?

      # TODO: complete me!

      decisions = []
      decisions << {
        'decisionType' => 'CompleteWorkflowExecution',
        #'completeWorkflowExecutionAttributes' => { 'result' => msg } }
        'completeWorkflowExecutionAttributes' => {} }

      @storage.swf_client.respond_decision_task_completed(
        'taskToken' => task_token,
        'decisions' => decisions)

      @storage.context.notify(
        'action' => 'decision_done',
        'fei' => msg['fei'],
        'wfid' => msg['wfid'],
        'put_at' => Ruote.now_to_utc_s)
    end
  end

  class ActivityTask < SwfTask

    def done(msg)

      return if any_msg?

      raise NotImplementedError
    end
  end
end

