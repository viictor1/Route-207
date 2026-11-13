extends Area2D

@export var label_volta: Label
@export var label_tempo: Label
@export var label_melhor: Label
@export var checkpoints: Array[Area2D]


var voltas = 0;
var tempo_volta: float = 0.0
var melhor_volta: float = INF
var proximo_checkpoint = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in checkpoints.size():
		checkpoints[i].body_entered.connect(_on_checkpoint.bind(i))

func _on_checkpoint(body: Node2D, i: int) -> void:
	if body.is_in_group("player") and i == proximo_checkpoint:
		proximo_checkpoint += 1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (voltas > 0):
		tempo_volta += delta
		label_tempo.text = "Tempo: " + formatar(tempo_volta)


func _on_body_entered(body: Node2D) -> void:
	if(body.is_in_group("player")):
		if voltas > 0 and proximo_checkpoint < checkpoints.size():
			return
		if voltas > 0 and tempo_volta < melhor_volta:
			melhor_volta = tempo_volta
			label_melhor.text = "Melhor Tempo: " + formatar(melhor_volta)

		tempo_volta = 0.0
		voltas +=1;
		label_volta.text = "Volta: " + str(voltas)
		proximo_checkpoint = 0

func formatar(t: float) -> String:
	return "%02d:%06.3f" % [int(t) / 60, fmod(t, 60.0)]
