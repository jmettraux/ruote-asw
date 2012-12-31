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


namespace :swf do

  task :setup_client do

    require 'rufus-json/automatic'
    require 'ruote-asw'

    @swf_client =
      Ruote::Asw::SwfClient.new(
        nil,
        ENV['AWS_ACCESS_KEY_ID'],
        ENV['AWS_SECRET_ACCESS_KEY'])
  end

  desc %{
    TODO
  }
  task :register_domain, [ :name ] => :setup_client do

    p :nada
  end

  desc %{
    list the SWF domains registered in the account
  }
  task :domains => :setup_client do

    pp @swf_client.list_domains(:registration_status => 'REGISTERED')
  end

  desc %{
    list the domains in the SWF account and the workflow/activity types in them
  }
  task :registered => :setup_client do

    @swf_client.list_domains(
      :registration_status => 'REGISTERED'
    )['domainInfos'].each do |d|

      puts "  #{d['name']}:"

      puts "    workflow type:"

      @swf_client.list_workflow_types(
        :domain => d['name'], :registration_status => 'REGISTERED'
      )['typeInfos'].each do |ti|
        wt = ti['workflowType']
        puts "      #{wt['name']} #{wt['version']}"
      end

      puts "    activity type:"

      @swf_client.list_activity_types(
        :domain => d['name'], :registration_status => 'REGISTERED'
      )['typeInfos'].each do |ti|
        at = ti['activityType']
        puts "      #{at['name']} #{at['version']}"
      end
    end
  end

  desc %{
    list the open workflow executions in a given domain
  }
  task :executions, [ :domain ] => :setup_client do |t, args|

    domain = args[:domain] || ENV['SWF_DOMAIN']

    raise ArgumentError.new(
      'missing :domain argument or SWF_DOMAIN env var'
    ) unless domain

    pp @swf_client.open_executions(domain)
  end

  desc %{
    /!\\ terminate all the open wf execution in the given domain
  }
  task :purge, [ :domain ] => :setup_client do |t, args|

    domain = args[:domain] || ENV['SWF_DOMAIN']

    raise ArgumentError.new(
      'missing :domain argument or SWF_DOMAIN env var'
    ) unless domain

    pp @swf_client.purge!(domain)
  end
end

