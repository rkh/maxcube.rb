require 'socket'

module Maxcube
  class Broadcast
    def initialize(port: 23272, broadcast: '<broadcast>'.freeze)
      @port      = port
      @broadcast = broadcast
    end
  
    def send(serial_number = nil, type)
      socket = UDPSocket.new
      socket.bind('0.0.0.0'.freeze, @port)
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
      socket.send("eQ3Max*#{serial_number ? "\0#{serial_number}" : ".**********"}#{type}", 0, @broadcast, @port)
      loop do
        data, addr         = socket.recvfrom(1024)
        _, sn, ri, rt, pl = data.unpack('a8a10aaa*') if data.start_with? "eQ3MaxAp"
        return parse_result(pl, serial_number: sn, request_type: rt, request_id: ri, udp_source_address: addr.last) if rt == type
      end
    ensure
      socket.close rescue nil if socket
    end
  
    def identity(serial_number = nil)
      send(serial_number, ?I)
    end
  
    def url(serial_number = nil)
      send(serial_number, ?h)
    end
  
    def network(serial_number = nil)
      send(serial_number, ?N)
    end
  
    private
  
    def parse_result(payload, **result)
      parse_method = :"parse_#{result.fetch(:request_type)}"
      raise ArgumentError, 'unknown UDP message type %p' % result[:request_type] unless respond_to? parse_method, true
      __send__(parse_method, payload).merge(result)
    end
  
    def parse_I(payload)
      _, rf_address, firmware_version = payload.unpack("aa3H*")
      { rf_address: rf_address, firmware_version: firmware_version.gsub(/^0(\d)(\d)(\d)$/, '\1.\2.\3') }
    end
  
    def parse_h(payload)
      port, rest   = payload.unpack("s>a*")
      server, path = rest.split(',', 2)
      { server_address: server, server_path: path, server_port: port }
    end
  
    def parse_N(payload)
      p payload
      a = payload.scan(/.{4}/).map { |s| s.bytes.map(&:to_s).join(?.) }
      { id_address: a[0], gateway: a[1], netmask: a[2], dns1: a[3], dns2: a[4] }
    end
  end
end