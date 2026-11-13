extends CanvasLayer


const MAIN_MENU_SCENE := "res://scenes/menu.tscn"

@onready var _resume_button: Button = $Center/MenuBox/ResumeButton
@onready var _main_menu_button: Button = $Center/MenuBox/MainMenuButton
@onready var _quit_button: Button = $Center/MenuBox/QuitButton


func _ready() -> void:
	_resume_button.pressed.connect(_on_resume_pressed)
	_main_menu_button.pressed.connect(_on_main_menu_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_on_resume_pressed()
		else:
			_open()
		get_viewport().set_input_as_handled()


func _open() -> void:
	get_tree().paused = true
	visible = true
	_resume_button.grab_focus()


func _on_resume_pressed() -> void:
	get_tree().paused = false
	visible = false


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
