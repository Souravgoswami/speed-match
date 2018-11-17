#!/usr/bin/ruby -W0
# Written by Sourav Goswami <souravgoswami@protonmail.com>. Thanks to Ruby2D community!
# GNU General Public License v3.0

require 'ruby2d'
STDOUT.sync = true

module Ruby2D
	def change_colour=(colour)
		opacity_ = self.opacity
		self.color = colour
		self.opacity = opacity_
	end

	def r=(r_val) self.color = [r_val, self.g, self.b, self.opacity] end
	def g=(g_val) self.color = [self.r, g_val, self.b, self.opacity] end
	def b=(b_val) self.color = [self.r, self.g, b_val, self.opacity] end
end

def main()
	$width, $height, $fps = 640, 480, 50

	$generate_colour = -> {
		colour = ''
		6.times do colour += [('a'..'f').to_a.sample, ('0'..'9').to_a.sample].sample end
		"##{colour}"
	}

	available_images = %w(3d_ball 5petals_filled balls bouquet bulb circle circles1 circles2 diamond_hex diamond dice
							hearts hexagon petals polygon ring ring2 rubik1 rubik2 star triangle triangle2)
	selected_images = available_images.sample(rand(1..2))

	$generate_image = ->(image_set) {
		image = Image.new("shapes/#{image_set.sample}.png")
		image.x, image.y, image.opacity = $width, $height/2 -image.height/1.5, 0.5
		image
	}

	$control = ->(object, type='reduce', val=0.05, threshold=0.65, max=1) {
		object.opacity -= val if object.opacity > threshold and type == 'reduce'
		object.opacity += val if object.opacity < max and type != 'reduce'
	}

	$t = ->(format='%s') { Time.new.strftime(format) }

	set title: 'Speed Match', width: $width, height: $height, resizable: true, background: $generate_colour.call, fps_cap: $fps
	bg = Image.new "images/bg.jpg", width: $width, height: $height, z: -10

	started = false

	button_yes_touched, button_yes_pressed = false, false
	button_yes = Rectangle.new width: $width/2 - 5, height: $height/5, x: 1
	button_yes.y = $height - button_yes.height - 1

	yes_text = Text.new 'YES', font: 'fonts/Aller_Lt.ttf', size: button_yes.height/1.5, color: 'teal'
	yes_text.x, yes_text.y = button_yes.x + button_yes.width/2 - yes_text.width/2, button_yes.y + button_yes.height/2 - yes_text.height/2

	button_no_touched, button_no_pressed = false, false
	button_no = Rectangle.new width: $width/2 - 5, height: $height/5
	button_no.x, button_no.y = button_yes.x + button_yes.width + 8, $height - button_no.height - 1

	no_text = Text.new 'NO', font: 'fonts/Aller_Lt.ttf', size: button_no.height/1.5, color: 'teal'
	no_text.x, no_text.y = button_no.x + button_no.width/2 - no_text.width/2, button_no.y + button_no.height/2 - no_text.height/2

	squares, squares_speed = [], []

	100.times do
		size = rand(6..10)
		square_ = Image.new 'shapes/1pixel_square.jpg', width: size, height: size, color: $generate_colour.call, z: -1
		square_.x, square_.y, square_.opacity = rand(0..$width - square_.width), rand(0..$height - square_.height), rand(0.2..0.5)
		squares << square_
		squares_speed << rand(1.0..4.0)
	end

	instruction_text_touched = false
	instruction_text = Text.new 'Does this card match the previous card?', font: 'fonts/Aller_Lt.ttf', size: 22
	instruction_text.x, instruction_text.y = $width/2 - instruction_text.width/2, 50

	items = []
	items_touched = false
	items << $generate_image.call(selected_images) if items.length < 1

	sound_correct = Sound.new 'sounds/131662__bertrof__game-sound-correct-v2.wav'
	sound_wrong = Sound.new 'sounds/131657__bertrof__game-sound-wrong.wav'

	correct = Image.new 'images/correct.png', width: $width/10, height: $width/10
	correct.x, correct.y, correct.opacity = $width/2 - correct.width/2, button_yes.y - correct.height - 5, 0

	wrong = Image.new 'images/wrong.png', width: $width/10, height: $width/10
	wrong.x, wrong.y, wrong.opacity = $width/2 - wrong.width/2, button_yes.y - wrong.height - 5, 0

	pause = Image.new 'images/pause.png', width: $width/20, height: $width/25, z: 12
	pausetext = Text.new "Play/Pause\t", x: pause.x + pause.width, y: pause.y, color: 'blue', z: 12
	pausebox_touched, pause_clicked, pausetext.opacity = false, false, 0
	pausebox = Rectangle.new width: pause.width - 3, height: pause.height - 2, x: 1, y: 1, z: 11

	pause_var = 0
	pause_blur = Rectangle.new x: 0, y: 0, width: $width, height: $height, color: 'black', z: 10
	pause_blur.opacity = 0.7

	resume_text_touched = false
	resume_text = Text.new 'Play!', font: 'fonts/Aller_Lt.ttf', size: 100, z: pause_blur.z
	resume_text.x, resume_text.y = pause_blur.x + pause_blur.width/2 - resume_text.width/2, pause_blur.y + pause_blur.height/2

	resume_button_touched = false
	resume_button = Image.new 'images/play_button.png', z: resume_text.z
	resume_button.x, resume_button.y = pause_blur.x + pause_blur.width/2 - resume_button.width/2, resume_text.y - resume_button.height

	about_button_touched = false
	about_button = Image.new 'images/bulb.png', z: resume_button.z
	about_button.x, about_button.y = $width - about_button.width - 5, button_no.y - about_button.height - 5

	power_touched = false
	power_button = Image.new 'images/power.png', z: resume_button.z, x: 5, y: about_button.y

	play_button2_touched = false
	play_button2 = Image.new 'images/play_button_64x64.png', z: resume_button.z, x: power_button.x, y: pausebox.y + pausebox.height + 5

	restart_touched = false
	restart_button = Image.new 'images/restart.png', x: about_button.x, y: play_button2.y, z: resume_button.z

	i, countdown, streak, score = 0.0, 0, 0, 0
	prev_item, next_item = '', ''

	score_touched = false
	score_text = Text.new "\tSCORE\t\t#{score}\t", font: 'fonts/Aller_Lt.ttf', size: 15, color: 'blue'
	score_text.x = $width - score_text.width - 5
	score_box = Rectangle.new x: score_text.x, y: score_text.y + 1, width: score_text.width, height: score_text.height, z: -1

	time_touched = false
	time_text = Text.new "\tTIME\t\t#{45}\t", font: 'fonts/Aller_Lt.ttf', size: 15, color: 'blue'
	time_text.x = score_text.x - time_text.width - 5
	time_box = Rectangle.new x: time_text.x, y: time_text.y + 1, width: time_text.width, height: time_text.height, z: -1

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
		button_yes_touched = false if k.key == 'left'
		button_no_touched = false if k.key == 'right'
	end

	on :mouse_move do |e|
		time_touched = time_box.contains?(e.x, e.y) ? true : false
		score_touched = score_box.contains?(e.x, e.y) ? true : false
		instruction_text_touched = instruction_text.contains?(e.x, e.y) ? true : false
		pausebox_touched = pausebox.contains?(e.x, e.y) ? true : false
		button_yes_touched = button_yes.contains?(e.x, e.y) ? true : false
		button_no_touched = button_no.contains?(e.x, e.y) ? true : false
		items.each do |val|
			items_touched = val.contains?(e.x, e.y) ? true : false
		end
		resume_button_touched = resume_button.contains?(e.x, e.y) ? true : false
		resume_text_touched = resume_text.contains?(e.x, e.y) ? true : false
		about_button_touched = about_button.contains?(e.x, e.y) ? true : false
		power_touched = power_button.contains?(e.x, e.y) ? true : false
		play_button2_touched = play_button2.contains?(e.x, e.y) ? true : false
		restart_touched = restart_button.contains?(e.x, e.y) ? true : false
	end

	on :mouse_down do |e|
		button_yes_pressed = button_yes.contains?(e.x, e.y) ? true : false
		button_no_pressed = button_no.contains?(e.x, e.y) ? true : false
		if pausebox.contains?(e.x, e.y) then pausebox.color, pause_clicked = 'yellow', true end
	end

	on :mouse_up do |e|
		pausebox.color, pause_clicked = 'white', false
		if (pausebox.contains?(e.x, e.y) and pausebox.opacity > 0.1) or \
						(resume_text.contains?(e.x, e.y) and resume_text.opacity > 0.1) or \
						(resume_button.contains?(e.x, e.y) and resume_button.opacity > 0.1) or \
						(play_button2.contains?(e.x, e.y) and play_button2.opacity > 0.1)
		then
			pause_var += 1
			countdown = 0
		end

		exit 0 if power_button.contains?(e.x, e.y) and power_button.opacity > 0.1
		Thread.new { system('ruby', 'stats.rb') } if about_button.contains?(e.x, e.y) and about_button.opacity > 0.1

		score, streak, i, pause_var, prev_item = 0, 0, 0.0, 1, '' if restart_button.contains?(e.x, e.y)
	end

	counter_label = Text.new '', font: 'fonts/Aller_Lt.ttf', size: 35, z: 12

	beep = Sound.new 'sounds/beep.wav'
	start_game_sound = Sound.new 'sounds/start_game.ogg'

	pressed = false
	counter = $t.call('%s').to_i

	update do
		unless pause_var % 2 == 0
			beep.play if countdown % $fps == 0 and !started
			countdown += 1
			case countdown/$fps
				when 0 then counter_label.text = '3'
				when 1 then counter_label.text = '2'
				when 2 then counter_label.text = '1'
				else
					start_game_sound.play if !started
					started = true
					counter_label.text = 'Go!'
					counter_label.opacity = 0
			end
			counter_label.x, counter_label.y = $width/2 - counter_label.width/2, pausebox.y + pausebox.height
		else
			started, countdown = false, 0
		end

		if pausebox_touched
			$control.call(pausetext, '', 0.05)
			pausebox.width += 10 if pausebox.width < pause.width + pausetext.width + 5
		else
			$control.call(pausetext, 'reduce', 0.1, 0)
			pausebox.width -= 10 if pausebox.width > pause.width - 3
		end

		if about_button_touched then about_button.g -= 0.08  if about_button.g > 0.5
			else about_button.g += 0.08 if about_button.g < 1 end

		if power_touched then power_button.g -= 0.08 if power_button.g > 0.5
			else power_button.g += 0.08 if power_button.g < 1 end

		if restart_touched then restart_button.g -= 0.08 if restart_button.g > 0.5
			else restart_button.g += 0.08 if restart_button.g < 1 end

		if play_button2_touched then play_button2.g -= 0.08 if play_button2.g > 0.5
			else play_button2.g += 0.08 if play_button2.g < 1 end

		if resume_text_touched or pausebox_touched or resume_button_touched or play_button2_touched
			resume_button.b -= 0.08 if resume_button.b > 0
			else resume_button.b += 0.08 if resume_button.b < 1 end


		timer = 45.-((i)./($fps)).to_f.round(1)
		if timer <= 0
			File.open('data/data', 'a+') { |file| file.puts(score) }
			pause_var = 0
			started = false
			instruction_text.text, instruction_text.opacity, instruction_text.z = "Game Over. Final Score\t #{score}. Click to show stat", 1, 12
			score, streak, prev_item = 0, 0, ''
			i = 0.0
		end

		instruction_text_touched ? $control.call(instruction_text) : $control.call(instruction_text, '') if pause_var == 0
		instruction_text.x = $width/2 - instruction_text.width/2

		squares.each_with_index do |square, i|
			square.y -= squares_speed[i]
			square.rotate += squares_speed[i]

			if square.y <= -square.height
				square.width = square.height = rand(6..10)
				squares_speed.delete_at(i)
				squares_speed.insert(i, rand(1.0..4.0))
				square.x, square.y, square.change_colour = rand(0..$width - square.width), $height + square.height, $generate_colour.call
			end
		end

		if started
			$control.call(pause_blur, 'reduce', 0.08, 0)
			$control.call(resume_text, 'reduce', 0.08, 0)
			$control.call(resume_button, 'reduce', 0.1, 0)
			$control.call(power_button, 'reduce', 0.1, 0)
			$control.call(about_button, 'reduce', 0.1, 0)
			$control.call(play_button2, 'reduce', 0.1, 0)
			$control.call(restart_button, 'reduce', 0.1, 0)

			i += 1.0

			score_text.text = "\tSCORE\t\t#{score}\t"
			time_text.text = "\tTIME\t\t#{timer}\t"

			instruction_text.text, instruction_text.z = 'Does this card match the previous card?', 0

			score_text.x = $width - score_text.width - 5
			time_text.x = score_text.x - time_text.width - 5

			score_box.width, score_box.height = score_text.width, score_text.height
			score_box.x, score_box.y = score_text.x, score_text.y + 1

			time_box.width, time_box.height = time_text.width, time_text.height
			time_box.x, time_box.y = time_text.x, time_text.y + 1

			$control.call(correct, 'reduce', 0.08, 0)
			$control.call(wrong, 'reduce', 0.08, 0)

			time_touched ? $control.call(time_box) : $control.call(time_box, '')
			score_touched ? $control.call(score_box) : $control.call(score_box, '')
			instruction_text_touched ? $control.call(instruction_text) : $control.call(instruction_text, '')

			pause_clicked ? $control.call(pausebox) : $control.call(pausebox, '')

			items << $generate_image.call(selected_images) if items.length < 1
			current_item = items[0].path

			if counter % $fps * 3 == 0
				counter += 1
				selected_images = available_images.sample(rand(1..2))
			end

			items.each do |val|
				items_touched ? $control.call(val, 'reduce', 0.08) : $control.call(val, '', 0.08)
				val.x -= $width/15 if val.x > $width/2.0 - val.width/2.0
			end

			if button_yes_touched
				$control.call(button_yes)
	 			yes_text.b += 0.15 if yes_text.b < 1
			else
				$control.call(button_yes, '')
				yes_text.color = [0.8, 0.8, 0.3, 1]
			end

			if button_no_touched
				$control.call(button_no)
	 			no_text.b += 0.15 if yes_text.b < 1
			else
				$control.call(button_no, '')
				no_text.color = [0.8, 0.8, 0.3, 1]
			end

			if button_yes_pressed
				pressed = true
				button_yes_pressed, button_no_pressed = false, false
				yes_text.color = 'red'
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
				button_yes_pressed, button_no_pressed = false, false
				no_text.color = 'red'
				unless prev_item == current_item
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

			if pressed
				items.each do |val|
					val.x -= $width/10.0
					val.opacity -= 0.2
					if val.x <= -val.width
						pressed = false
						prev_item = val.path
						val.remove
						items.shift
					end
				end
			end
			else
				resume_button_touched ? $control.call(resume_button) : $control.call(resume_button, '')
				resume_text_touched ? $control.call(resume_text) : $control.call(resume_text, '')
				$control.call(power_button, '')
				$control.call(about_button, '')
				$control.call(play_button2, '')
				$control.call(restart_button, '')
				$control.call(pause_blur, '', 0.05, 0.65, 0.7)
		end
		counter += 1
	end
	Window.show
end
main
