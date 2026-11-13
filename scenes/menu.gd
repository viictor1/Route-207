extends Control


const GAME_SCENE := "res://scenes/main.tscn"

@onready var _time_attack_button: Button = $Center/MenuBox/TimeAttackButton
@onready var _quit_button: Button = $Center/MenuBox/QuitButton


func _ready() -> void:
	_time_attack_button.pressed.connect(_on_time_attack_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_time_attack_button.grab_focus()


func _on_time_attack_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
