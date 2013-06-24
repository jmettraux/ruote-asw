
#
# spec'ing ruote-asw
#
# Sun Jan  6 17:03:44 JST 2013
#

module DashboardHelper

  def setup_dboard

    @dboard =
      Ruote::Dashboard.new(
        Ruote::Asw::DecisionWorker.new(
        Ruote::Asw::ActivityWorker.new(
          new_storage(:no_preparation => true))))

    @dboard.noisy = (ENV['NOISY'] == 'true')
  end

  def teardown_dboard

    return unless @dboard

    sleep(0.500)

    @dboard.shutdown
    @dboard.storage.purge!

  rescue => e

    #return if e.message.match(/^UnknownResourceFault: /)

    puts '~' * 80
    puts '~ teardown issue ~'
    p e
    p e.message
    puts e.backtrace
  end
end

RSpec.configure { |c| c.include(DashboardHelper) }

