
#
# spec'ing ruote-asw
#
# Thu Dec 27 09:33:30 JST 2012
#
# Onomichi
#

require 'spec_helper'


describe 'ruote-asw with a MemoryStore' do

  before(:each) do

    @dboard =
      Ruote::Dashboard.new(
        Ruote::Asw::DecisionWorker.new(
        Ruote::Asw::ActivityWorker.new(
          new_storage(:memory_store => true))))
  end

  describe 'sequence' do

    it 'flows from a to b' do

      pdef =
        Ruote.define do
          noop # a
          noop # b
        end
    end
  end
end

