#!/usr/bin/env ruby
# Written by Sourav Goswami <souravgoswami@protonmail.com>. Thanks to Ruby2D community!
# GNU General Public License v3.0

%w(ruby2d securerandom open3).each { |g| require(g) }

STDOUT.sync = true
PATH = File.dirname(__FILE__)
FONT = File.join(PATH, 'fonts' ,'Aller_Lt.ttf')

module Ruby2D
	def change_colour=(colour) self.opacity, self.color = opacity, colour end

	def opacify(step = 0.05, threshold = 0.5)
		self.opacity -= step if opacity > threshold
		itself
	end

	def illuminate(step = 0.05, threshold = 1)
		self.opacity += step if opacity < threshold
		itself
	end
end

def main()
	$width, $height, $fps = 640, 480, 45

	available_images = %w(3d_ball 5petals_filled balls bouquet bulb circle circles1 circles2 diamond_hex diamond dice
							hearts hexagon petals polygon ring ring2 rubik1 rubik2 star triangle triangle2)
	selected_images = available_images.sample(rand(1..2))

	items = []
	$t = ->(format='%s') { Time.new.strftime(format) }
	$generate_image = ->(image_set) {
		image = Image.new(File.join(PATH, 'shapes', "#{image_set.sample}.png"))
		image.x, image.y, image.opacity = $width, $height / 2 - image.height / 1.5, 0.5
		items.push(image)
	}

	set title: 'Speed Match', width: $width, height: $height, resizable: true, background: "##{SecureRandom.hex(3)}", fps_cap: $fps
	Image.new File.join(PATH, 'images', 'bg.jpg'), width: $width, height: $height, z: -10

	button_yes = Rectangle.new width: $width/2 - 5, height: $height/5, x: 1
	button_yes.y = $height - button_yes.height - 1

	yes_text = Text.new 'YES', font: FONT, size: button_yes.height / 1.5, color: 'teal'
	yes_text.x, yes_text.y = button_yes.x + button_yes.width/2 - yes_text.width/2, button_yes.y + button_yes.height/2 - yes_text.height/2

	button_no = Rectangle.new width: $width/2 - 5, height: $height/5
	button_no.x, button_no.y = button_yes.x + button_yes.width + 8, $height - button_no.height - 1

	no_text = Text.new 'NO', font: FONT, size: button_no.height/1.5, color: 'teal'
	no_text.x, no_text.y = button_no.x + button_no.width/2 - no_text.width/2, button_no.y + button_no.height/2 - no_text.height/2

	squares = Array.new(100) { Image.new(File.join(PATH, 'shapes', '1pixel_square.jpg'), color: "##{SecureRandom.hex(3)}", z: -1, width: (sz= rand(6..10)), height: sz, x: rand($width), y: rand($height)) }
	squares_size = squares.size

	instruction_text = Text.new 'Does this card match the previous card?', font: FONT, size: 22
	instruction_text.x, instruction_text.y = $width/2 - instruction_text.width/2, 50

	button_yes_touched = button_yes_pressed = button_no_touched = button_no_pressed = resume_text_touched = started = false
	instruction_text_touched = resume_button_touched = about_button_touched = power_touched = play_button2_touched = restart_touched = score_touched = time_touched = items_touched = false

	sound_correct = Sound.new(File.join(PATH, 'sounds', '131662__bertrof__game-sound-correct-v2.wav'))
	sound_wrong = Sound.new(File.join(PATH, 'sounds', '131657__bertrof__game-sound-wrong.wav'))

	correct = Image.new(File.join(PATH, 'images', 'correct.png'), width: $width/10, height: $width / 10)
	correct.x, correct.y, correct.opacity = $width / 2 - correct.width / 2, button_yes.y - correct.height - 5, 0

	wrong = Image.new File.join(PATH, 'images', 'wrong.png'), width: $width/10, height: $width/10
	wrong.x, wrong.y, wrong.opacity = $width/2 - wrong.width/2, button_yes.y - wrong.height - 5, 0

	pause = Image.new File.join(PATH, 'images', 'pause.png'), width: $width/20, height: $width/25, z: 12
	pausetext = Text.new "Play/Pause\t", font: FONT,  x: pause.x + pause.width, y: pause.y, color: 'blue', z: 12
	pausebox_touched, pause_clicked, pausetext.opacity = false, false, 0
	pausebox = Rectangle.new width: pause.width - 3, height: pause.height - 2, x: 1, y: 1, z: 11

	pause_var = 0
	pause_blur = Rectangle.new x: 0, y: 0, width: $width, height: $height, color: 'black', z: 10
	pause_blur.opacity = 0.7

	resume_text = Text.new 'Play!', font: FONT, size: 100, z: pause_blur.z
	resume_text.x, resume_text.y = pause_blur.x + pause_blur.width/2 - resume_text.width / 2, pause_blur.y + pause_blur.height / 2

	resume_button = Image.new File.join(PATH, 'images', 'play_button.png'), z: resume_text.z
	resume_button.x, resume_button.y = pause_blur.x + pause_blur.width / 2 - resume_button.width / 2, resume_text.y - resume_button.height

	about_button = Image.new File.join(PATH, 'images', 'bulb.png'), z: resume_button.z
	about_button.x, about_button.y = $width - about_button.width - 5, button_no.y - about_button.height - 5

	power_button = Image.new File.join(PATH, 'images', 'power.png'), z: resume_button.z, x: 5, y: about_button.y
	play_button2 = Image.new File.join(PATH, 'images', 'play_button_64x64.png'), z: resume_button.z, x: power_button.x, y: pausebox.y + pausebox.height + 5
	restart_button = Image.new File.join(PATH, 'images', 'restart.png'), x: about_button.x, y: play_button2.y, z: resume_button.z

	i, countdown, streak, score = 0.0, 0, 0, 0
	prev_item = ''

	score_text = Text.new "\tSCORE\t\t#{score}\t", font: FONT, size: 15, color: 'blue'
	score_text.x = $width - score_text.width - 5
	score_box = Rectangle.new x: score_text.x, y: score_text.y + 1, width: score_text.width, height: score_text.height, z: -1

	time_text = Text.new "\tTIME\t\t#{45}\t", font: FONT, size: 15, color: 'blue'
	time_text.x = score_text.x - time_text.width - 5
	time_box = Rectangle.new x: time_text.x, y: time_text.y + 1, width: time_text.width, height: time_text.height, z: -1

	hideable_objects = power_button, about_button, play_button2, restart_button

	on :key_held do |k|
		button_yes_touched = true if %w(left a 1 j).include?(k.key)
		button_no_touched = true if %w(right d 3 ;).include?(k.key)
	end

	on :key_down do |k|
		button_yes_pressed = true if %w(left a 1 j).include?(k.key) or k.key.match(/4/)
		button_no_pressed = true if %w(right d 3 ;).include?(k.key) or k.key.match(/6/)
		pause_var += 1 if %w(space escape f).include?(k.key)
	end

	on :key_up do |k|
		button_yes_touched = false if %w(left a 1 j).include?(k.key)
		button_no_touched = false if %w(right d 3 ;).include?(k.key)
	end

	on :mouse_move do |e|
		%w(time_touched score_touched instruction_text_touched, pausebox_touched button_yes_touched button_no_touched resume_button_touched resume_text_touched
			about_button_touched power_touched play_button2_touched restart_touched).zip(%w(time_box score_box instruction_text pausebox button_yes button_no
				resume_button resume_text about_button power_button play_button2 restart_button)).each { |b| eval("#{b[0]} = #{b[1]}.contains?(e.x, e.y)") }

		items.each { |val| items_touched = val.contains?(e.x, e.y) }
	end

	on :mouse_down do |e|
		button_yes_pressed, button_no_pressed = button_yes.contains?(e.x, e.y), button_no.contains?(e.x, e.y)
		pausebox.color, pause_clicked = '#FFBC00', true if pausebox.contains?(e.x, e.y)
	end

	on :mouse_up do |e|
		pausebox.color, pause_clicked = '#FFFFFF', false
		if (pausebox.contains?(e.x, e.y) and pausebox.opacity > 0.1) or \
						(resume_text.contains?(e.x, e.y) and resume_text.opacity > 0.1) or \
						(resume_button.contains?(e.x, e.y) and resume_button.opacity > 0.1) or \
						(play_button2.contains?(e.x, e.y) and play_button2.opacity > 0.1)
		then
			pause_var += 1
			countdown = 0
		end

		close if power_button.contains?(e.x, e.y) and power_button.opacity > 0.1
		Open3.pipeline_start("#{File.join(RbConfig::CONFIG['bindir'], 'ruby')} #{File.join(PATH, 'stats.rb')}") if about_button.contains?(e.x, e.y)
		score, streak, i, pause_var, prev_item = 0, 0, 0.0, 1, '' if restart_button.contains?(e.x, e.y)
	end

	counter_label = Text.new '', font: FONT, size: 35, z: 12

	beep = Sound.new File.join(PATH, 'sounds', 'beep.wav')
	start_game_sound = Sound.new File.join(PATH, 'sounds', 'start_game.ogg')

	pressed = false
	counter = $t.call('%s').to_i

	update do
		unless pause_var % 2 == 0
			beep.play if countdown % $fps == 0 and !started
			counter_label.opacity = 1 if !started
			countdown += 1

			counter_label.text = case countdown/$fps
				when 0 then '3'
				when 1 then '2'
				when 2 then '1'
				else
					start_game_sound.play if !started
					started = true
					'Go!'
			end
			counter_label.x, counter_label.y = $width / 2 - counter_label.width / 2, pausebox.y + pausebox.height
		else
			started, countdown = false, 0
		end

		if pausebox_touched
			pausetext.illuminate
			pausebox.width += 10 if pausebox.width < pause.width + pausetext.width + 5
		else
			pausetext.opacify(0.05, 0)
			pausebox.width -= 10 if pausebox.width > pause.width - 3
		end

		if about_button_touched then about_button.g -= 0.08  if about_button.g > 0.5
		else about_button.g += 0.08 if about_button.g < 1
		end

		if power_touched then power_button.g -= 0.08 if power_button.g > 0.5
		else power_button.g += 0.08 if power_button.g < 1
		end

		if restart_touched then restart_button.g -= 0.08 if restart_button.g > 0.5
		else restart_button.g += 0.08 if restart_button.g < 1
		end

		if play_button2_touched then play_button2.g -= 0.08 if play_button2.g > 0.5
		else play_button2.g += 0.08 if play_button2.g < 1
		end

		if resume_text_touched or pausebox_touched or resume_button_touched or play_button2_touched
			resume_button.b -= 0.08 if resume_button.b > 0
		else
			resume_button.b += 0.08 if resume_button.b < 1
		end

		timer = 45.-((i)./($fps)).to_f.round(1)
		if timer <= 0
			File.open(File.join(PATH, 'data', 'data'), 'a+') { |file| file.puts(score) }
			started = false
			instruction_text.text, instruction_text.opacity, instruction_text.z = "Game Over. Final Score\t #{score}. Click to show stat", 1, 12 unless instruction_text.z == 1
			score, streak, pause_var, prev_item = 0, 0, 0, ''
			i = 0.0
		end

		instruction_text_touched ? instruction_text.opacify : instruction_text.illuminate if pause_var == 0
		instruction_text.x = $width / 2 - instruction_text.width / 2

		squares.each_with_index do |square, i|
			square.y -= i / (squares_size / 2.0) + 2
			square.rotate += square.width / 2.0

			if square.y <= -square.height
				square.width = square.height = rand(6..10)
				square.x, square.y, square.change_colour = rand(0..$width - square.width), $height + square.height, "##{SecureRandom.hex(3)}"
			end
		end

		if started
			i += 1.0

			hideable_objects.each { |el| el.opacify(0.08, 0) }
			pause_blur.opacify(0.08, 0)
			resume_text.opacify(0.08, 0)
			resume_button.opacify(0.08, 0)
			counter_label.opacify(0.08, 0)

			score_text.text = "\tSCORE\t\t#{score}\t"
			time_text.text = "\tTIME\t\t#{timer}\t"
			instruction_text.text, instruction_text.z = 'Does this card match the previous card?', 0 unless instruction_text.z == 0

			score_text.x = $width - score_text.width - 5
			time_text.x = score_text.x - time_text.width - 5

			score_box.width, score_box.height = score_text.width, score_text.height
			score_box.x, score_box.y = score_text.x, score_text.y + 1

			time_box.width, time_box.height = time_text.width, time_text.height
			time_box.x, time_box.y = time_text.x, time_text.y + 1

			correct.opacify(0.08, 0)
			wrong.opacify(0.08, 0)

			time_touched ? time_box.opacify : time_box.illuminate
			score_touched ? score_box.opacify : score_box.illuminate
			instruction_text_touched ? instruction_text.opacify : instruction_text.illuminate

			pause_clicked ? pausebox.opacify : pausebox.illuminate

			$generate_image.call(selected_images) if items.length < 1
			current_item = items[0].path

			if counter % $fps * 3 == 0
				counter += 1
				selected_images = available_images.sample(rand(1..2))
			end

			items.each do |val|
				items_touched ? val.opacify : val.illuminate
				val.x -= $width / 15 if val.x > $width / 2.0 - val.width/2.0
			end

			if button_yes_touched
				button_yes.opacify
	 			yes_text.b += 0.15 if yes_text.b < 1
			else
				button_yes.illuminate
				yes_text.color = [0.8, 0.8, 0.3, 1]
			end

			if button_no_touched
				button_no.opacify
	 			no_text.b += 0.15 if yes_text.b < 1
			else
				button_no.illuminate
				no_text.color = [0.8, 0.8, 0.3, 1]
			end

			if button_yes_pressed
				pressed = true
				button_yes_pressed = button_no_pressed = false
				yes_text.color = '#FF0000'
				if prev_item == current_item
					streak += 1
					correct.opacity = 1
					score += 1 * streak
					sound_correct.play
				else
					streak = 0
					wrong.opacity = 1
					sound_wrong.play
					score -= 1 * streak
				end
			end

			if button_no_pressed
				pressed = true
				no_text.color = '#FF0000'
				button_yes_pressed = button_no_pressed = false
				unless prev_item == current_item
					streak += 1
					score += 1 * streak
					correct.opacity = 1
					sound_correct.play
				else
					streak = 0
					score -= 1 * streak
					wrong.opacity = 1
					sound_wrong.play
				end
			end

			if pressed
				items.each do |val|
					val.x -= $width/10.0
					val.opacity -= 0.2
					val.rotate -= 15

					if val.x <= -val.width
						pressed = false
						prev_item = val.path
						val.remove
						items.shift
					end
				end
			end
		else
			hideable_objects.each(&:illuminate)
			resume_button_touched ? resume_button.opacify : resume_button.illuminate
			resume_text_touched ? resume_text.opacify : resume_text.illuminate
			pause_blur.illuminate(0.05, 0.5)
		end
		counter += 1
	end
end

begin
	main
	Window.show
rescue Exception => e
	Kernel.warn("Uh oh, Caught an Exception:\n#{' ' * 4}#{e}\n#{'-' * (e.to_s.length + 4)}\nError Details:\n#{' ' * 4}#{e.backtrace.join("\n" + ' ' * 4)}\n")
end
