module Maxcube
  class Device
    class Cube < Device
    end

    class Thermostat < Device
      def update_config(config)
        _, room_id, _, rest = config.unpack("a5ca12a*")
        update(:room_id, room_id)
        rest
      end
    end

    class HeatingThermostat < Thermostat
      attr_accessor :comfort_temperature, :eco_temperature, :max_temperature, :min_temperature, :temperature_offset, :window_open_temperature,
        :window_open_duration, :boost, :decalcification, :max_valve_setting, :valve_offset

      def update_config(config)
        rest   = super
        single = rest[0,11].bytes
        rest   = rest[11..-1] # weekly program, yet to decode

        update(:comfort_temperature,     single[0]/2r)
        update(:eco_temperature,         single[1]/2r)
        update(:max_temperature,         single[2]/2r)
        update(:min_temperature,         single[3]/2r)
        update(:temperature_offset,      single[4]/2r-(7/2r))
        update(:window_open_temperature, single[5]/2r)
        update(:window_open_duration,    single[6]/5r)
        update(:boost,                   single[7])
        update(:decalcification,         single[8])
        update(:max_valve_setting,       single[9]*100/255r)
        update(:valve_offset,            single[10]*100/255r)
      end
    end

    class HeatingThermostatPlus < HeatingThermostat
    end

    class WallMountedThermostat < Thermostat
      attr_accessor :comfort_temperature, :eco_temperature, :max_temperature, :min_temperature

      def update_config(config)
        rest   = super
        single = rest[0,4].bytes
        rest   = rest[4..-1] # weekly program, yet to decode

        update(:comfort_temperature,     single[0]/2r)
        update(:eco_temperature,         single[1]/2r)
        update(:max_temperature,         single[2]/2r)
        update(:min_temperature,         single[3]/2r)
      end
    end

    class ShutterContact < Thermostat
    end

    class PushButton < Device
    end

    class UnknownDevice < Device
    end

    DEVICE_TYPES = [
      Cube,
      HeatingThermostat,
      HeatingThermostatPlus,
      WallMountedThermostat,
      ShutterContact,
      PushButton,
    ]

    def self.new(type = nil, connection, **attributes)
      return super(connection, **attributes) unless type
      factory = DEVICE_TYPES[type] || UnknownDevice
      factory.new(connection, **attributes)
    end

    attr_reader :connection
    attr_accessor :room_id, :device_name, :serial_number, :rf_address
    alias name device_name

    def initialize(connection, **attributes)
      attributes.each { |attribute, value| public_send("#{attribute}=", value) }
      @connection = connection
    end

    def update(attribute, value)
      # hook logic goes here
      @room = nil if attribute.to_sym == :room_id
      public_send("#{attribute}=", value)
    end

    def update_config(config)
    end

    def room
      @room ||= @connection.room(room_id)
    end

    def inspect
      "#<%p:%p:%p>" % [self.class, room.name, device_name]
    end
  end
end