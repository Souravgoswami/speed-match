# Speed Match 🦄
Speed match is a brain training game (not based on real brain test).
![screenshot](https://github.com/Souravgoswami/speed-match/blob/master/Screenshots/a.png)

## Running the Source Code ⚙️
  + Install [Ruby](https://www.ruby-lang.org/en/downloads/) and [Ruby2D](http://www.ruby2d.com/learn/get-started/)
  + Download the ![zip file here](https://github.com/Souravgoswami/speed-match/archive/master.zip).
  + Unzip the zip file.
  + Run `main.rb` with Ruby Interpreter.

### Alternatively (using bundler)
  + Install [Ruby](https://www.ruby-lang.org/en/downloads/)
  + Install bundler `gem install bundler`
  + Install dependencies `bundle install`
  + Execute the main file `bundle exec ruby main.rb`

## How to Play 🎮
+ You first have to look at the Card. And see if the card matches the previous card.
+ There are a YES and a NO button. Press YES if the currently shown card matches the previous card, otherwise Press NO.
+ Speed Match has 45 seconds time limit.
+ You have to try to get most of the response right. Answering right in a row will give you more and more bonus for each response. Responding wrong will take away all your streak.

## Controls 🐭⌨️
  **The game can be played both with the mouse and the keyboard (no joystick support yet)**
  ### Keyboard ⌨️
   + To trigger YES button, press the left key, a key, 1 key or j key
   + To trigger NO button, press right key, d key, 3 key or ; key
   + To trigger Pause/Play button, press space key, escape key or f key.

  ### Mouse and On-screen Buttons 🐭
   #### While the Game is Not Paused ▶️
   + Press any of the mouse buttons (primary, middle, left) on YES or NO will trigger YES or NO respectively.
   + Press any of the mouse buttons (primary, middle, left) on the Pause button to pause the game.

   #### While the Game is Paused ⏸
   + Press the Big Play button, small Play button, the Play text or the Play/Pause button to start playing.
   + Press the bulb icon to get statistics, and learn more about the game.
   + Press the Reset button to restart the game.
   + Press the Power button to exit the game.

## Windows 🗔
There are two windows:
+ The main.rb file opens the game.
+ The stats.rb file opens your performance records.
+ As discussed in the "Mouse and On-screen Buttons" section, you can click on the Bulb icon while the game is paused to see your performance records.

## Statistics 📊
After launching main.rb, and playing until timeout (45 seconds), your score will be written to ./data/data file as a hexadecimal value. The stats.rb file reads the ./data/data file and converts it back to decimal.

![screenshot](https://github.com/Souravgoswami/speed-match/blob/master/Screenshots/c.png)

*It is to be noted that the stats.rb is not based on real-life mental tests. Any contribution is welcomed.*

## Screenshot 📸
![screenshot](https://github.com/Souravgoswami/speed-match/blob/master/Screenshots/b.png)

## Bugs 🐞
If you find any bug (which will be always caught 🥅🐛🥅 ) or feature request, please let me know via GitHub or email me souravgoswami@protonmail.com
