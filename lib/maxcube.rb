require 'maxcube/broadcast'
require 'maxcube/connection'
require 'maxcube/room'
require 'maxcube/device'

module Maxcube
  extend self

  def connect(address = nil, port = nil)
    if address.nil?
      result  = Broadcast.new.identity
      address = result[:udp_source_address]
    end

    if port.nil?
      port   = 80 if result and result[:firmware_version] < '1.0.e'
      port ||= 62910
    end

    Connection.new(address, port)
  end
end
