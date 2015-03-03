require 'lifx'
require 'optparse'

options = {
	:offset => 0,
	:lowerc => 0,
	:upperc => 360,
	:lowerd => 1,
	:upperd => 60,
	:sat => 1.0,
	:brightness => 1.0,
	:kelvin => 3500,
	:customkel => false,
	:customsat => false,
	:custombri => false,
}

OptionParser.new do |opts|
	opts.banner = "Usage: play.rb [options]"

	opts.on("-c", "--color [COLOR]", "Set the color once") do |c|
		options[:color] = c
	end

	opts.on("--hue-min [VAL]", Integer,
			"Set the minimum hue") do |v|
		options[:lowerc] = v
		until options[:upperc] > options[:lowerc]
			options[:upperc] += 360
		end
	end

	opts.on("--hue-max [VAL]", Integer,
			"Set the maximum hue") do |v|
		options[:upperc] = v
		until options[:upperc] > options[:lowerc]
			options[:lowerc] -= 360
		end
	end

	opts.on("-l", "--duration-lbound [SECONDS]", Integer,
			"Minimum duration between changes") do |l|
		options[:lowerd] = l
	end

	opts.on("-u", "--duration-ubound [SECONDS]", Integer,
			"Maximum duration between changes") do |u|
		options[:upperd] = u
	end

	opts.on("-d", "--duration [SECONDS]", Integer,
			"Fixed duration between changes") do |d|
		options[:lowerd] = d
		options[:upperd] = d
	end

	opts.on("-s", "--saturation [SAT]", Float,
		   "Set the saturation (0..1)") do |s|
		options[:sat] = s
		options[:customsat] = true
	end

	opts.on("-b", "--brightness [VAL]", Float,
		   "Set the brightness (0..1)") do |s|
		options[:brightness] = s
		options[:custombri] = true
	end

	opts.on("-k", "--kelvin [VAL]", Float,
		   "Set the kelvin (2500..9000)") do |s|
		options[:kelvin] = s
		options[:customkel] = true
	end

end.parse!

client = LIFX::Client.lan

client.discover! do |c| 
	c.lights.with_label('Main')
end

light = client.lights.with_label('Main')

if options[:color]
	if options[:color] == 'white'
		light.set_color(LIFX::Color.white(brightness: options[:brightness], kelvin: options[:kelvin]), duration: options[:lowerd])
	else
		light.set_color(LIFX::Color.public_send(
			options[:color].to_sym, 
			saturation: options[:sat],
			brightness: options[:brightness],
			kelvin: options[:kelvin]
		), duration: options[:lowerd])
	end
	client.flush
else
	begin
		d = rand(options[:lowerd]..options[:upperd])
		hue = rand(options[:lowerc]..options[:upperc]) % 360
		kelvin = rand(2500..9000)
		sat = rand()
		bright = rand()
		if options[:customkel]
			kelvin = options[:kelvin]
		end
		if options[:customsat]
			sat = options[:sat]
		end
		if options[:custombri]
			bright = options[:brightness]
		end
		puts "%2d seconds to [%3d, %3f, %3f @ %4dK]" % [d, hue, sat, bright, kelvin]
		light.set_color LIFX::Color.new(hue, sat, bright, kelvin), duration: d
		client.flush
		sleep d
	end while true
end
