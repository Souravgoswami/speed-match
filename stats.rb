#!/usr/bin/ruby
require 'ruby2d'
# Written by Sourav Goswami <souravgoswami@protonmail.com>. Thanks to Ruby2D community!
# GNU General Public License v3.0

module Ruby2D def get_colour() [self.r, self.g, self.b, self.opacity] end end

def main
	$width, $height, $fps = 640, 480, 50
	set title: 'Speed Match Statistics', width: $width, height: $height, fps_cap: $fps, background: 'white'

	$generate_colour = -> {
		colour = ''
		6.times do colour += [('0'..'9').to_a.sample, ('a'..'f').to_a.sample].sample end
		"##{colour}"
	}

	$control = ->(object, type='reduce', val=0.05, threshold=0.6) {
		if type.start_with?('r')
			object.opacity -= val if object.opacity > threshold
		else
			object.opacity += val if object.opacity < 1
		end
	}

	stat_bg = Image.new 'images/bg_stat_window.png', width: $width, height: $height
	stat_bg.opacity = 0.2

	read_score = File.readlines('data/data').last(7).map(&:to_i)
	last_score = read_score[-2]
	score = read_score[-1]

	if score < 250 then iqtype, you_in = 'Very Low', 0
		elsif score < 500 then iqtype, you_in = 'Low', 1
		elsif score < 750 then iqtype, you_in = 'Average', 2
		elsif score < 900 then iqtype, you_in = 'Good', 3
		else iqtype, you_in = 'Excellent', 4
	end

	game_details = <<EOF
Speed Match is a game where you have to decide if the
previous image matches the current image.
The images are often reffered to as cards.

How to play: Just tap yes if the previous card
match the old one, or else, just tap no.

Benefit: Playing this game may increase your
brain's flexibility.

Scores: The graph on the right side shows
the details.

Your score:
You have scored #{score}.
As we like to put, "You are #{iqtype}."

Your past score: #{last_score}.

Your last 7 scores:
#{read_score}
EOF
	game_details = game_details.split("\n")

	game_details_texts = []
	game_details.each_with_index do |l, i|
		game_details_texts << Text.new(l, font: 'fonts/Aller_Lt.ttf', x: 5, y: i * 20, size: 20, color: 'black')
	end

	note = Text.new 'NOTE: Neither this game nor these score statistics are based on real life mental test.',
		font: 'fonts/Aller_Lt.ttf', color: 'red', x: 5, size: 15
	note.y = $height - note.height - 5

	triangles = []
	j = 10
	20.step(260, 60) do |i|
		triangles << Triangle.new(
				x1: $height - j + 50 + 60, y1: 0 + i,
				x2: $height - j + 100 + 60, y2: 350,
				x3: $height - j + 60, y3: 350,
 				color: $generate_colour.call)
		j += 50
	end
	triangles.reverse!

	a_line = Line.new color: 'black', x1: triangles[0].x3, x2: triangles[-1].x2, y1: triangles[0].y2 + 10, y2: triangles[-1].y2 + 10

	very_low_text = Text.new 'Very Low', font: 'fonts/Aller_Lt.ttf', color: triangles[0].get_colour, size: 15
	very_low_text.x, very_low_text.y = triangles[0].x1 - very_low_text.width/2, triangles[0].y1 - very_low_text.height

	low_text = Text.new 'Low', font: 'fonts/Aller_Lt.ttf', color: triangles[1].get_colour, size: 15
	low_text.x, low_text.y = triangles[1].x1 - low_text.width/2, triangles[1].y1 - low_text.height

	average_text = Text.new 'Average', font: 'fonts/Aller_Lt.ttf', color: triangles[2].get_colour, size: 15
	average_text.x, average_text.y = triangles[2].x1 - average_text.width/2, triangles[2].y1 - average_text.height

	good_text = Text.new 'Good', font: 'fonts/Aller_Lt.ttf', color: triangles[3].get_colour, size: 15
	good_text.x, good_text.y = triangles[3].x1 - good_text.width/2, triangles[3].y1 - good_text.height

	excellent_text = Text.new 'Excellent', font: 'fonts/Aller_Lt.ttf', color: triangles[4].get_colour, size: 15
	excellent_text.x, excellent_text.y = triangles[4].x1 - excellent_text.width/2, triangles[4].y1 - excellent_text.height

	you = Text.new 'YOU', font: 'fonts/Aller_Lt.ttf', size: 15
	you.x = triangles[you_in].x1 - you.width/2
	you.y = triangles[you_in].y1/2 + triangles[you_in].y2/2 - you.height/2

	details_raw = <<EOF
					 VERY LOW: (less than 250) You have to improve yourself.
 					LOW: (250 to 499) You need to make some improvements.
 					AVERAGE: (500 to 749) Your brain's performance is normal.
 					GOOD: (750 to 899) Your brain works very fast.
 					EXCELLENT: (more than 899) Your brain is highly flexible.
EOF
	details_raw = details_raw.split("\n")

	height = 0
	details_info = []

	details_raw.each_with_index do |c, i|
		details = Text.new(c, font: 'fonts/Aller_Lt.ttf', color: triangles[i].get_colour, x: a_line.x1 - 25, y: a_line.y1 + 5 + height, size: 11)
		details_info << details
		height += details.height
	end

	hovered_on_triangle, details_hover = nil, false

	on :key_down do |k| exit 0 if %w(escape p q space).include?(k.key) end

	on :mouse_move do |e|
		if very_low_text.contains?(e.x, e.y) then very_low_text.color = [0,0,0,1]
			elsif very_low_text.get_colour == [0,0,0,1] then very_low_text.color = $generate_colour.call end

		if low_text.contains?(e.x, e.y) then low_text.color = [0,0,0,1]
			elsif low_text.get_colour == [0,0,0,1] then low_text.color = $generate_colour.call end

		if average_text.contains?(e.x, e.y) then average_text.color = [0,0,0,1]
			elsif average_text.get_colour == [0,0,0,1] then average_text.color = $generate_colour.call end

		if good_text.contains?(e.x, e.y) then good_text.color = [0,0,0,1]
			elsif good_text.get_colour == [0,0,0,1] then good_text.color = $generate_colour.call end

		if excellent_text.contains?(e.x, e.y) then excellent_text.color = [0,0,0,1]
			elsif excellent_text.get_colour == [0,0,0,1] then excellent_text.color = $generate_colour.call end

		game_details_texts.each do |val| val.color = val.contains?(e.x, e.y) ? '#dd00a6' : '#000000' end
	end

	update do
		triangles[0].color = very_low_text.get_colour
		triangles[1].color = low_text.get_colour
		triangles[2].color = average_text.get_colour
		triangles[3].color = good_text.get_colour
		triangles[4].color = excellent_text.get_colour

		details_info.each_with_index { |val, i| val.color = triangles[i].get_colour }
	end
	Window.show
end
main
