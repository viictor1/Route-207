class_name Car
extends CharacterBody2D


const GROUP := &"player"

@export var model: CarModel
@export var sprite_rotation_offset_degrees: float = 90.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group(GROUP)
	if model == null:
		model = CarModel.new()
	rotation = model.heading
	_sprite.rotation = deg_to_rad(sprite_rotation_offset_degrees)


func _physics_process(delta: float) -> void:
	var throttle := Input.get_axis("brake", "throttle")
	var steer := Input.get_axis("steer_left", "steer_right")
	var handbrake := Input.is_action_pressed("handbrake")

	model.step(throttle, steer, handbrake, delta)

	velocity = model.velocity
	rotation = model.heading
	move_and_slide()
	model.velocity = get_real_velocity()
