#!/usr/bin/env ruby
# Written by Sourav Goswami <souravgoswami@protonmail.com>. Thanks to Ruby2D community!
# GNU General Public License v3.0
%w(ruby2d openssl).each { |g| require(g) }

@path = File.dirname(__FILE__)
Font = File.join(@path, 'fonts', 'Aller_Lt.ttf')

module Ruby2D
	def contain?(obj) contains?(obj.x, obj.y) end
	def decrease_opacity(step = 0.05, threshold = 0) self.opacity -= step if opacity > threshold end
	def increase_opacity(step = 0.05, threshold = 1) self.opacity += step if opacity < threshold end
end

define_method(:main) do
	$width, $height, $fps = 640, 480, 50
	set title: 'Chalkboard Challenge Statistics', width: $width, height: $height, fps_cap: $fps, background: 'white', resizable: true
	Image.new(File.join(@path, 'images', 'bg_stat_window.png'), width: $width, height: $height, opacity: 0.3)

	scores = File.exist?(File.join(@path, 'data', 'data')) ? IO.readlines(File.join(@path, 'data', 'data')).map { |x| [x.strip].pack('h*').to_i } : [0]

	read_score, score = scores.last(5), scores[-1]
	read_score = score = 0 if read_score.empty?
	very_low, low, avg, good = 0...250, 250...500, 500...750, 750...1000

	you_in = case score
		when very_low then 0
		when low then 1
		when avg then 2
		when good then 3
		else 4
	end

	game_details = <<~EOF.strip
		Speed Match is a game where you have to decide if the
		previous image matches the current image.
		The images are often reffered to as cards.

		How to play: Just tap the YES Button if the previous
		card matches the old one, or else, just tap the NO
		Button.

		Benefit: Playing this game may increase your
		brain's flexibility.
		-------------------------------------------
		Your Current Score: #{score.to_i}.
		Your Past Score: #{read_score[-2] ? read_score[-2].to_i : read_score[-1].to_i}.
		Your Best Score: #{scores.max.to_i}.
	EOF

	game_details << if scores.length > 5
		"\nYour last 5 Scores:\n\t" << read_score.join(', ')
	elsif scores.length > 1
		"\nYour last #{scores.length} Scores:\n\t" << read_score.join(', ')
	else
		''
	end << "\n-------------------------------------------"

	game_details = game_details.split("\n")

	gd = game_details.size.to_f
	game_details_texts, game_details_touched = Array.new(game_details.size) { |i| Text.new(game_details[i], font: Font, x: 5, y: i * 20, size: 15, color: [1 - i / gd, 0.5 - i / (gd * 2.0), i / gd, 1] ) }, false
	triangles, touched_tri = 20.step(260, 60).map { |i| Triangle.new(x1: $height - i + 120, y1: 0 + i, x2: $height - i + 170, y2: 350, x3: $height - i + 70, y3: 350, color: [1, i / 600.0, 1 - i / 300.0, 1]) }.reverse, nil
	particles = Array.new(100) do
		sample, size = triangles.sample, [1, 2].sample
		Square.new(x: rand(sample.x3..sample.x2), y: sample.y2 - size , size: size, color: '#FFFFFF')
	end
	particles_opacity = Array.new(particles.size) { rand(0.003..0.03) }

	grade_texts = ['Very Low', 'Low', 'Average', 'Good', 'Excellent'].map.with_index do |el, index|
		text = Text.new(el, font: Font, color: '#000000', size: 12)
		text.x, text.y = triangles[index].x1 - text.width / 2, triangles[index].y1 - text.height
		text
	end

	you = Text.new 'YOU', font: Font , size: 12
	you.x = triangles[you_in].x1 - you.width / 2
	you.y = triangles[you_in].y1 / 2 + triangles[you_in].y2 / 2 - you.height / 2

	details_raw = <<~EOF.each_line.map { |el| ' ' * 6 + el }
					VERY LOW: (< #{very_low.last}) You must improve.
 					LOW: (#{very_low.last} - #{low.last - 1}) You have to improve.
 					AVERAGE: (#{low.last} - #{avg.last - 1}) Normal performance.
 					GOOD: (#{avg.last} - #{good.last - 1}) Wow! That's quick!
 					EXCELLENT: (> #{good.last - 1}) You are godlike!
	EOF

	a_line = Line.new color: '#000000', x1: triangles[0].x3, x2: triangles[-1].x2, y1: triangles[0].y2 + 10, y2: triangles[-1].y2 + 10
	details_info = Array.new(details_raw.size) { |i| Text.new(details_raw[i], font: Font, x: a_line.x1 - 20, y: a_line.y1 + 5 + i * 18, size: 11, color: [1, i / 10.0, i / 5.0, 1]) }

	on(:key_down) { |k| close if %w(escape p q space).include?(k.key) }

	on :mouse_move do |e|
		triangles.each do |el|
			if el.contain?(e)
				touched_tri = el
				break
			else
				touched_tri = nil
			end
		end

		game_details_texts.each do |el|
			if el.contain?(e)
				game_details_touched = el
				break
			else
				game_details_touched = nil
			end
		end
	end

	update do
		particles.each_with_index do |el, index|
			if el.opacity <= 0 || el.x < triangles[0].x3 || el.x > triangles[-1].x2
				sample = triangles.sample
				el.opacity = 1
				el.x, el.y = rand(sample.x3..sample.x2), sample.y2
			else
				el.x += Math.sin(index)
				el.y -= index / particles.size.to_f
				el.decrease_opacity(particles_opacity[index])
			end
		end

		game_details_touched ? game_details_texts.each { |el| el.equal?(game_details_touched) ? el.increase_opacity : el.decrease_opacity(0.05, 0.4)  } : game_details_texts.each(&:increase_opacity)

		if touched_tri
			triangles.each_with_index do |el, index|
				if el.equal?(touched_tri)
					el.increase_opacity
					details_info[index].increase_opacity
					grade_texts[index].increase_opacity
				else
					el.decrease_opacity(0.05, 0.4)
					details_info[index].decrease_opacity(0.05, 0.4)
					grade_texts[index].decrease_opacity(0.05, 0.4)
				end
			end
		else
			triangles.each(&:increase_opacity)
			details_info.each(&:increase_opacity)
			grade_texts.each(&:increase_opacity)
		end
	end

	'NOTE: Neither this game nor these score statistics are based on real life mental test'.each_char.with_index do |c, i|
		Text.new(c, font: Font, x: 5 + i * 6, size: 10, y: $height - 18, color: [1, i / 100.0, 1 - i / 10.0, 1])
	end
end

begin
	main
	Window.show
rescue SystemExit, Interrupt
	puts
rescue Exception => e
	Kernel.warn("Uh oh, Caught an Exception:\n#{' ' * 4}#{e}\n#{'-' * (e.to_s.length + 4)}\nError Details:\n#{' ' * 4}#{e.backtrace.join("\n" + ' ' * 4)}\n")
end
