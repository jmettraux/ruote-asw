
#
# testing ruote-mon
#
# Mon Dec 24 17:03:32 JST 2012
#

require 'ruote-asw'


def new_storage(opts)

  #opts['wait_logger_timeout'] = 180
    # SWF can be quite demanding
  opts['swf_task_list'] ||= "ruote_asw_test_task_list_#{Time.now.to_f}_#{rand}"

  if ENV['RUOTE_ASW_STORE'].to_s.start_with?('m')
    #
    # use in-memory store

    Ruote::Asw::Storage.new(
      RA.aki, RA.sak, RA.region, RA.test_domain, Ruote::Asw::MemoryStore.new, opts)

  else
    #
    # will use a S3Store with the 'ruote_asw_test' bucket

    Ruote::Asw::Storage.new(
      RA.aki, RA.sak, RA.region, RA.test_domain, opts)
  end
end

