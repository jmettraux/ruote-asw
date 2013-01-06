
#
# spec'ing ruote-asw
#
# Sun Jan  6 17:03:44 JST 2013
#

module DashboardHelper

  def setup_dboard_with_memory_store

    # TODO: use different task lists for each spec/test

    @dboard =
      Ruote::Dashboard.new(
        Ruote::Asw::DecisionWorker.new(
        Ruote::Asw::ActivityWorker.new(
          new_storage(:memory_store => true, :no_preparation => true))))

    @dboard.noisy = (ENV['NOISY'] == 'true')
  end

  def teardown_dboard

    @dboard.shutdown
    @dboard.storage.purge!

  rescue => e
    puts '~' * 80
    puts '~ teardown issue ~'
    p e
    puts caller
  end
end

RSpec.configure { |c| c.include(DashboardHelper) }

