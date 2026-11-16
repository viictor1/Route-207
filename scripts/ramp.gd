extends Area2D

@export var duracao_pulo: float = 0.75
@export var impulso_pulo: float = 140.0
@export var velocidade_minima: float = 120.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if body is Car and body.modelo.velocidade_frente >= velocidade_minima:
		body.aplica_rampa(duracao_pulo, impulso_pulo)
