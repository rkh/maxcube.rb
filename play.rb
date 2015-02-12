$:.unshift './lib'
require 'maxcube'

cube = Maxcube.connect

puts "Comfort Temparatures", ""
cube.rooms.each do |room|
  puts "#{room.name}:"
  room.devices.each do |device|
    puts " #{"#{device.name}:".ljust(30)} #{device.comfort_temperature.to_f}˚C"
  end
  puts
end