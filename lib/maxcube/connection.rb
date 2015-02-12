require 'socket'
require 'strscan'
require 'base64'

module Maxcube
  class Connection
    attr_reader :address, :port, :serial_number, :rf_address, :firmware_version, :http_connection_id, :duty_cycle, :free_memory_slots, :rooms, :devices

    def initialize(address, port)
      @address, @port = address, port
      @socket         = TCPSocket.new(address, port)
      last_message    = read_message until last_message == 'L'
    end

    def inspect
      "#<%p:%s:%d>" % [self.class, address, port]
    end

    def room(name_or_id)
      rooms.detect { |room| room.room_id == name_or_id or room.room_name == name_or_id }
    end

    def device(room_name_or_id, device_name)
      room(room_name_or_id).device(device_name)
    end

    def by_rf_address(address)
      devices.detect { | device | device.rf_address     == address } or
      rooms.detect   { | room   | room.group_rf_address == address }
    end

    private

    def read_message
      return unless match = /^(.):(.*)\r\n$/.match(@socket.gets)
      message, payload    = match[1], match[2]
      payload             = payload.split(",")
      send("read_message_#{message}", *payload) if respond_to?("read_message_#{message}", true)
      message
    end

    def read_message_H(serial_number, rf_address, firmware_version, unknown, http_connection_id, duty_cycle, free_memory_slots, cube_date, cube_time, state_cube_time, ntp_counter)
      @serial_numer       = serial_number
      @rf_address         = rf_address
      @firmware_version   = firmware_version.gsub(/^0(\d)(\d)(\d)$/, '\1.\2.\3')
      @http_connection_id = http_connection_id
      @duty_cycle         = duty_cycle.to_i(16)
      @free_memory_slots  = free_memory_slots.to_i(16)
    end

    def read_message_M(index, count, content)
      @rooms       = []
      @devices     = []
      scanner      = StringScanner.new(Base64.decode64(content))
      scanner.pos += 2

      room_count = scanner.getch.ord
      room_count.times do
        room_id     = scanner.getch.ord
        name_length = scanner.getch.ord
        room_name   = scanner.scan(/.{#{name_length}}/)
        group_rf    = scanner.scan(/.{3}/)
        @rooms << Room.new(self, room_id: room_id, room_name: room_name, group_rf_address: format_rf(group_rf))
      end

      device_count = scanner.getch.ord
      device_count.times do
        device_type   = scanner.getch.ord
        rf_address    = scanner.scan(/.{3}/)
        serial_number = scanner.scan(/.{10}/)
        name_length   = scanner.getch.ord
        device_name   = scanner.scan(/.{#{name_length}}/)
        room_id       = scanner.getch.ord
        @devices << Device.new(device_type, self, room_id: room_id, device_name: device_name, serial_number: serial_number, rf_address: format_rf(rf_address))
      end
    end

    def format_rf(rf)
      "%02x%02x%02x" % rf.bytes
    end

    def read_message_C(device_address, content)
      return unless device = by_rf_address(device_address)
      content &&= Base64.decode64(content)
      device.update_config(content)
    end
  end
end
