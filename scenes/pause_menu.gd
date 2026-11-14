extends CanvasLayer


const MAIN_MENU_SCENE := "res://scenes/menu.tscn"

@onready var _resume_button: Button = $Center/MenuBox/ResumeButton
@onready var _main_menu_button: Button = $Center/MenuBox/MainMenuButton
@onready var _quit_button: Button = $Center/MenuBox/QuitButton
@onready var _slider_geral: HSlider = $Center/MenuBox/SliderGeral
@onready var _slider_musica: HSlider = $Center/MenuBox/SliderMusica
@onready var _slider_efeitos: HSlider = $Center/MenuBox/SliderEfeitos


func _ready() -> void:
	_resume_button.pressed.connect(_on_resume_pressed)
	_main_menu_button.pressed.connect(_on_main_menu_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_slider_geral.value_changed.connect(_on_volume_changed.bind("Master"))
	_slider_musica.value_changed.connect(_on_volume_changed.bind("Musica"))
	_slider_efeitos.value_changed.connect(_on_volume_changed.bind("Efeitos"))


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
	
func _on_volume_changed(value: float, bus_name: String) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(bus_name), value)
