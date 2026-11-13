class_name Car
extends CharacterBody2D


const GROUP := &"player"

const CAR_WHEELS: Array[Vector2] = [
	Vector2(36.0, -15.0),  # Front left
	Vector2(36.0, 15.0),   # Front right
	Vector2(-36.0, -15.0), # Rear left
	Vector2(-36.0, 15.0)   # Rear right
]

const MULT_ASPHALT: float = 1.0
const MULT_GRASS: float = 0.62
const MULT_SAND: float = 0.42

@export var model: CarModel
@export var sprite_rotation_offset_degrees: float = 90.0
@export var mapa_sprite: Sprite2D
@export var mascara_superficie: Texture2D = preload("res://assets/sprites/mapa-eua-mask.png")
@onready var _sprite: Sprite2D = $Sprite2D

var _mask_image: Image
var _mask_size: Vector2

func _ready() -> void:
	add_to_group(GROUP)
	if model == null:
		model = CarModel.new()
	rotation = model.heading
	_sprite.rotation = deg_to_rad(sprite_rotation_offset_degrees)

	if mapa_sprite == null:
		mapa_sprite = get_parent().get_node_or_null("MapaEua") as Sprite2D

	if mascara_superficie != null:
		_mask_image = mascara_superficie.get_image()
		_mask_size = Vector2(_mask_image.get_size())

func apply_oil(duration: float = 1.3) -> void:
	model.trigger_oil(duration)

func apply_ramp(duration: float = 0.75, boost: float = 140.0) -> void:
	model.trigger_ramp(duration, boost)

func _physics_process(delta: float) -> void:
	if model.air_timer > 0.0:
		var progress := 1.0 - (model.air_timer / maxf(model.air_duration, 0.01))
		_sprite.scale = Vector2.ONE * (1.0 + 0.42 * sin(progress * PI))
	else:
		_sprite.scale = Vector2.ONE
		_update_terrain()

	var throttle := Input.get_axis("brake", "throttle")
	var steer := Input.get_axis("steer_left", "steer_right")
	var handbrake := Input.is_action_pressed("handbrake")

	model.step(throttle, steer, handbrake, delta)

	velocity = model.velocity
	rotation = model.heading
	move_and_slide()
	model.velocity = get_real_velocity()

func _update_terrain() -> void:
	if _mask_image == null or mapa_sprite == null or mapa_sprite.texture == null:
		model.surface_speed_mult = MULT_ASPHALT
		return

	var tex_size := mapa_sprite.texture.get_size()
	var soma_mult := 0.0

	for local_point in CAR_WHEELS:
		var current_pos := to_global(local_point)
		var map_pos := mapa_sprite.to_local(current_pos)
		var uv := (map_pos + tex_size * 0.5) / tex_size

		var px := int(clampf(uv.x, 0.0, 0.999) * _mask_size.x)
		var py := int(clampf(uv.y, 0.0, 0.999) * _mask_size.y)
		var cor := _mask_image.get_pixel(px, py)

		if cor.a < 0.2:
			soma_mult += MULT_ASPHALT
		elif cor.r > 0.6 and cor.g > 0.6: # Sand
			soma_mult += MULT_SAND
		elif cor.g > 0.45 and cor.r < 0.35 and cor.g > cor.b * 1.4: # Grass
			soma_mult += MULT_GRASS
		else: # Black / Asphalt
			soma_mult += MULT_ASPHALT

	model.surface_speed_mult = soma_mult / float(CAR_WHEELS.size())
