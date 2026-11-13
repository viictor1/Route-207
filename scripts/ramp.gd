extends Area2D

@export var jump_duration: float = 0.75
@export var jump_boost: float = 140.0
@export var min_speed: float = 120.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Car and body.model.speed >= min_speed:
		body.apply_ramp(jump_duration, jump_boost)
