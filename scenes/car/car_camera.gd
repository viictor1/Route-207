extends Camera2D

@export var caminho_alvo: NodePath
@export var tempo_antecipacao: float = 0.22
@export var distancia_maxima: float = 160.0

var alvo: CharacterBody2D


func _ready():
	if caminho_alvo != NodePath():
		alvo = get_node_or_null(caminho_alvo) as CharacterBody2D
	if alvo == null:
		alvo = get_parent().get_node_or_null("Car") as CharacterBody2D
	if alvo != null:
		global_position = alvo.global_position


func _physics_process(_delta: float):
	if alvo == null:
		return

	var avanco := alvo.velocity * tempo_antecipacao
	if avanco.length() > distancia_maxima:
		avanco = avanco.normalized() * distancia_maxima

	global_position = alvo.global_position + avanco
