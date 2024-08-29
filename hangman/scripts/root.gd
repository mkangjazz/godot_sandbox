extends Node2D

signal restart_button_pressed;

const blank_space_scene:Resource = preload("res://scenes/blank_space.tscn");
const win_scene:Resource = preload("res://scenes/win.tscn");
const lose_scene:Resource = preload("res://scenes/lose.tscn");
const allowed_strikes:int = 5;

@onready var keyboard_keys_container = %Keyboard
@onready var blank_spaces_container = %BlankSpaces
@onready var incorrect_guesses_container = %IncorrectGuesses
@onready var player_actions_container = %CenterContainer

# need to switch between index num and char, due to unique values
var current_word:String = "";
var incorrect_guesses:Array = [];
var keyboard_keys:Dictionary = {};
var blank_spaces:Array = [];
var word_bank:Array = [
	"apple",
	"pear",
	"news",
	"award",
	"grimace",
	"stack",
];
var allowed_string:String = "qwertyuiopasdfghjklzxcvbnm"; # break into rows? chunk into diff sizes?
var allowed_chars:Array = [];
var accept_keyboard_input:bool = false;

func _ready():
	set_up_allowed_chars();
	set_up_new_game();
	pass

func _input(event):
	if event is InputEventKey and event.pressed:
		var keycode_string:String = OS.get_keycode_string(event.keycode);
		var key:String = keycode_string.to_lower();

		# only accept VERY specific keycodes for our pseudo keyboard
		if keyboard_keys:
			if keyboard_keys.has(key):
				if accept_keyboard_input:
					if not keyboard_keys[key].disabled:
						keyboard_keys[key].pressed.emit();
	pass
	
func _process(_delta):
	pass

func remove_all_blank_spaces():
	for n in blank_spaces_container.get_children():
		n.queue_free()
	pass

func set_up_current_word():
	var random_word:String = get_random_word();
	
	current_word = random_word;
	pass;

func set_up_blank_spaces():
	for letter in current_word:
		var space = blank_space_scene.instantiate()
		blank_spaces_container.add_child(space)

		space.setCharacter(letter);
		blank_spaces.append(space);
	pass

func handle_keyboard_keypress(key:String):
	keyboard_keys[key].disabled = true;
	handle_player_input_submission(key);
	pass

func set_up_allowed_chars():
	for letter in allowed_string:
		if !allowed_chars.has(letter):
			allowed_chars.append(letter)
	pass

func remove_all_keyboard_keys():
	for n in keyboard_keys_container.get_children():
		n.queue_free()
	pass
	
func remove_all_incorrect_guesses():
	for n in incorrect_guesses_container.get_children():
		n.queue_free()
	pass
		
func set_up_player_keyboard():
	for key in allowed_chars:
		var button = Button.new();
		button.text = key.to_upper();
		button.toggle_mode = true;
		button.grow_horizontal = true
		button.connect("pressed", handle_keyboard_keypress.bind(key))
		keyboard_keys_container.add_child(button)
		keyboard_keys[key] = button;
	pass

func set_up_new_game():
	current_word = "";
	incorrect_guesses = [];
	keyboard_keys = {};
	blank_spaces = [];
	accept_keyboard_input = false;
	
	remove_all_blank_spaces();
	remove_all_keyboard_keys();
	remove_all_incorrect_guesses();

	set_up_current_word();
	set_up_blank_spaces();
	set_up_player_keyboard();
	show_keyboard();

	print("current_word: ", current_word)

	pass

func get_random_word():
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var	random_int = rng.randi_range(
		0,
		word_bank.size() - 1
	);
	
	return word_bank[random_int];

func handle_player_input_submission(key:String):
	var lower_key:String = key.to_lower();
	var found_indexes:Array = [];
	
	if !allowed_chars.has(lower_key):
		return;

	if current_word.find(lower_key) == -1:
		var label = Label.new();

		label.text = lower_key.to_upper();
		incorrect_guesses_container.add_child(label)
		incorrect_guesses.append(lower_key);
	else:
		var i = 0;
		for letter in current_word:
			if (letter == lower_key):
				found_indexes.append(i);
			i += 1;

	for index in found_indexes:
		blank_spaces[index].showAnswer();
		pass
	
	check_win_lose_conditions();

	pass

func show_keyboard():
	keyboard_keys_container.show()
	accept_keyboard_input = true;

func hide_keyboard():
	keyboard_keys_container.hide()
	accept_keyboard_input = false;

func _on_play_again():
	print("PLAY AGAIN YAY");
	set_up_new_game();
	pass 

func show_win():
	print("YOU WIN")
	var win = win_scene.instantiate();

	player_actions_container.add_child(win);
	win.play_again.connect(_on_play_again)
	pass

func show_lose():
	print("YOU LOSE")
	var lose = lose_scene.instantiate();
	player_actions_container.add_child(lose);
	
	lose.play_again.connect(_on_play_again)
	pass

func check_win_lose_conditions():
	if incorrect_guesses.size() >= allowed_strikes:
		hide_keyboard();
		show_lose();
	else:
		var all_spaces_revealed = true;

		for space in blank_spaces:
			if space.revealAnswer == false:
				all_spaces_revealed = false;
				break;
			pass

		if all_spaces_revealed:
			hide_keyboard();
			show_win();
	pass
