
#
# testing ruote-mon
#
# Mon Dec 24 17:03:32 JST 2012
#

require 'ruote-asw'


def new_storage(opts)

  aki = ENV['AWS_ACCESS_KEY_ID']
  sak = ENV['AWS_SECRET_ACCESS_KEY']

  if opts.delete(:memory_store) == true
    #
    # use in-memory store

    Ruote::Asw::Storage.new(
      aki, sak, 'ruote_asw_test', Ruote::Asw::MemoryStore.new, opts)

  else
    #
    # will use a S3Store with the 'ruote_asw_test' bucket

    Ruote::Asw::Storage.new(
      aki, sak, 'ruote_asw_test', opts)
  end
end

