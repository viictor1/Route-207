extends Camera2D


@export var target_path: NodePath
@export var look_ahead_time: float = 0.22
@export var max_look_ahead: float = 160.0

var _target: CharacterBody2D


func _ready() -> void:
	if target_path != NodePath():
		_target = get_node_or_null(target_path) as CharacterBody2D
	if _target != null:
		global_position = _target.global_position


func _physics_process(_delta: float) -> void:
	if _target == null:
		return
	var lead := _target.velocity * look_ahead_time
	if lead.length() > max_look_ahead:
		lead = lead.normalized() * max_look_ahead
	global_position = _target.global_position + lead
