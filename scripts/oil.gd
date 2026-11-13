extends Area2D

@export var effect_duration: float = 1.3


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Car:
		body.apply_oil(effect_duration)
