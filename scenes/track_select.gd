extends Control

const MAIN_MENU_SCENE := "res://scenes/menu.tscn"
const TRACK_1_SCENE := "res://scenes/main.tscn"
const TRACK_2_SCENE := "res://scenes/pista_2.tscn"

@onready var _track_1_button: Button = $Center/MenuBox/Track1Button
@onready var _track_2_button: Button = $Center/MenuBox/Track2Button
@onready var _back_button: Button = $Center/MenuBox/BackButton


func _ready() -> void:
	_track_1_button.pressed.connect(_on_track_1_pressed)
	_track_2_button.pressed.connect(_on_track_2_pressed)
	_back_button.pressed.connect(_on_back_pressed)


	if not ResourceLoader.exists(TRACK_2_SCENE):
		_track_2_button.disabled = true
		_track_2_button.text += " (Mais pistas em breve)"

	_track_1_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


func _on_track_1_pressed() -> void:
	get_tree().change_scene_to_file(TRACK_1_SCENE)


func _on_track_2_pressed() -> void:
	if ResourceLoader.exists(TRACK_2_SCENE):
		get_tree().change_scene_to_file(TRACK_2_SCENE)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
