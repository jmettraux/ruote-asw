
require 'ruote'

require 'ruote/asw/version'
require 'ruote/asw/stores/s3'
require 'ruote/asw/stores/memory'
require 'ruote/asw/storage'
require 'ruote/asw/workers'


module Ruote::Asw
  #
  # a few helpers

  def self.test_domain; ENV['ASW_DOMAIN'] || 'ruote-asw-test'; end

  def self.region; ENV['AWS_REGION'] || 'ireland'; end
  def self.aki; ENV['AWS_ACCESS_KEY_ID']; end
  def self.sak; ENV['AWS_SECRET_ACCESS_KEY']; end
end

