class_name Car
extends CharacterBody2D

const GRUPO := &"player"

const RODAS_CARRO: Array[Vector2] = [
	Vector2(36.0, -15.0),  # Dianteira esquerda
	Vector2(36.0, 15.0),   # Dianteira direita
	Vector2(-36.0, -15.0), # Traseira esquerda
	Vector2(-36.0, 15.0)   # Traseira direita
]

const MULT_ASFALTO: float = 1.0
const MULT_GRAMA: float = 0.62
const MULT_AREIA: float = 0.42

@export var modelo: CarModel
@export var rotacao_inicial_sprite: float = 90.0
@export var mapa_sprite: Sprite2D
@export var mascara_superficie: Texture2D = preload("res://assets/sprites/mapa-eua-mask.png")

@onready var sprite: Sprite2D = $Sprite2D
@onready var som_motor: AudioStreamPlayer2D = $SomMotor

var imagem_mascara: Image
var tamanho_mascara: Vector2


func _ready():
	add_to_group(GRUPO)
	if modelo == null:
		modelo = CarModel.new()
	rotation = modelo.angulo
	sprite.rotation = deg_to_rad(rotacao_inicial_sprite)

	if mapa_sprite == null:
		mapa_sprite = get_parent().get_node_or_null("MapaEua") as Sprite2D

	if mascara_superficie != null:
		imagem_mascara = mascara_superficie.get_image()
		tamanho_mascara = Vector2(imagem_mascara.get_size())


func aplica_oleo(duracao: float = 1.3):
	modelo.aplicar_oleo(duracao)


func aplica_rampa(duracao: float = 0.75, impulso: float = 140.0):
	modelo.aplicar_rampa(duracao, impulso)


func _physics_process(delta: float):
	if modelo.tempo_no_ar > 0.0:
		var progresso := 1.0 - (modelo.tempo_no_ar / maxf(modelo.duracao_salto, 0.01))
		sprite.scale = Vector2.ONE * (1.0 + 0.42 * sin(progresso * PI))
	else:
		sprite.scale = Vector2.ONE

	atualizar_terreno()

	var acelerador := Input.get_axis("brake", "throttle")
	var direcao := Input.get_axis("steer_left", "steer_right")
	var freio_mao := Input.is_action_pressed("handbrake")

	modelo.atualizar_fisica(acelerador, direcao, freio_mao, delta)

	velocity = modelo.velocidade
	rotation = modelo.angulo
	move_and_slide()

	for i in get_slide_collision_count():
		var normal := get_slide_collision(i).get_normal()
		if modelo.velocidade.dot(normal) < 0.0:
			modelo.velocidade = modelo.velocidade.slide(normal)

	var t := clampf(absf(modelo.velocidade_frente) / modelo.velocidade_maxima, 0.0, 1.0)
	som_motor.pitch_scale = lerpf(0.7, 1.6, t)
	som_motor.volume_db = lerpf(-37.0, -7.0, minf(t * 4.0, 1.0))


func atualizar_terreno():
	if imagem_mascara == null or mapa_sprite == null or mapa_sprite.texture == null:
		modelo.multiplicador_superficie = MULT_ASFALTO
		return

	var tamanho_textura := mapa_sprite.texture.get_size()
	var soma_mult := 0.0

	for ponto_roda in RODAS_CARRO:
		var pos_global := to_global(ponto_roda)
		var pos_mapa := mapa_sprite.to_local(pos_global)
		var uv := (pos_mapa + tamanho_textura * 0.5) / tamanho_textura
		var px := int(clampf(uv.x, 0.0, 0.999) * tamanho_mascara.x)
		var py := int(clampf(uv.y, 0.0, 0.999) * tamanho_mascara.y)
		var cor := imagem_mascara.get_pixel(px, py)

		if cor.a < 0.2:
			soma_mult += MULT_ASFALTO
		elif cor.r > 0.6 and cor.g > 0.6: # Areia
			soma_mult += MULT_AREIA
		elif cor.g > 0.45 and cor.r < 0.35 and cor.g > cor.b * 1.4: # Grama
			soma_mult += MULT_GRAMA
		else: # Asfalto
			soma_mult += MULT_ASFALTO

	modelo.multiplicador_superficie = soma_mult / float(RODAS_CARRO.size())
