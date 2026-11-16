extends Area2D

@export var label_volta: Label
@export var label_tempo: Label
@export var label_melhor: Label
@export var checkpoints: Array[Area2D]

var voltas: int = 0
var tempo_volta: float = 0.0
var melhor_volta: float = INF
var proximo_checkpoint: int = 0


func _ready():
	for i in checkpoints.size():
		checkpoints[i].body_entered.connect(_on_checkpoint.bind(i))


func _process(delta: float):
	if voltas > 0:
		tempo_volta += delta
		label_tempo.text = "A: " + formatar(tempo_volta)


func _on_checkpoint(body: Node2D, indice: int):
	if body.is_in_group("player") and indice == proximo_checkpoint:
		proximo_checkpoint += 1


func _on_body_entered(body: Node2D):
	if not body.is_in_group("player"):
		return

	if voltas > 0 and proximo_checkpoint < checkpoints.size():
		return

	if voltas > 0 and tempo_volta < melhor_volta:
		melhor_volta = tempo_volta
		label_melhor.text = "MV: " + formatar(melhor_volta)

	tempo_volta = 0.0
	voltas += 1
	label_volta.text = "V: " + str(voltas)
	proximo_checkpoint = 0


func formatar(tempo: float) -> String:
	return "%02d:%06.3f" % [int(tempo) / 60, fmod(tempo, 60.0)]
