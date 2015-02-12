module Maxcube
  class Room
    attr_reader :connection
    attr_accessor :room_id, :room_name, :group_rf_address
    alias name room_name

    def initialize(connection, **attributes)
      attributes.each { |attribute, value| public_send("#{attribute}=", value) }
      @connection = connection
    end

    def devices
      @devices ||= connection.devices.select do |device|
        device.room == self
      end
    end

    def device(name)
      devices.detect { |device| room.device_name == name }
    end

    def inspect
      "#<%p:%p>" % [self.class, room_name]
    end
  end
end
