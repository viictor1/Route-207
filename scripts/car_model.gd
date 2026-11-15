class_name CarModel
extends Resource

@export_group("Velocidade e Aceleracao")
@export var velocidade_maxima: float = 750.0
@export var velocidade_maxima_re: float = 200.0
@export var aceleracao: float = 500.0
@export var forca_freio_mao: float = 500.0
@export var desaceleracao_inercia: float = 90.0
@export var arrasto: float = 0.35
@export var desaceleracao_fora_pista: float = 950.0

@export_group("Direcao")
@export var taxa_curva_maxima: float = 4.0
@export var velocidade_ref_curva: float = 150.0
@export var reducao_curva_alta_vel: float = 0.65
@export var suavizacao_direcao: float = 9.0

@export_group("Aderencia")
@export var aderencia: float = 11.0
@export var aderencia_freio_mao: float = 1.6

@export_group("Limites de Estado")
@export var limite_drift: float = 260.0
@export var limite_parado: float = 14.0

var velocidade: Vector2 = Vector2.ZERO
var angulo: float = 0.0
var direcao_atual: float = 0.0
var velocidade_frente: float = 0.0
var velocidade_lateral: float = 0.0
var angulo_derrapagem: float = 0.0
var fazendo_drift: bool = false
var esta_parado: bool = true

var multiplicador_superficie: float = 1.0
var tempo_oleo: float = 0.0
var tempo_no_ar: float = 0.0
var duracao_salto: float = 0.75
var sentido_giro_oleo: float = 1.0


func aplicar_oleo(duracao: float = 1.3):
	if tempo_no_ar > 0.0:
		return
	tempo_oleo = maxf(tempo_oleo, duracao)
	sentido_giro_oleo = -1.0 if randf() < 0.5 else 1.0


func aplicar_rampa(duracao: float = 0.75, impulso: float = 140.0):
	if tempo_no_ar > 0.0:
		return
	duracao_salto = duracao
	tempo_no_ar = duracao
	tempo_oleo = 0.0
	velocidade += Vector2.RIGHT.rotated(angulo) * impulso


func atualizar_fisica(acelerador: float, entrada_direcao: float, freio_mao: bool, delta: float):
	if tempo_no_ar > 0.0:
		tempo_no_ar = maxf(tempo_no_ar - delta, 0.0)
		var frente_ar := Vector2.RIGHT.rotated(angulo)
		var direita_ar := frente_ar.orthogonal()
		velocidade_frente = velocidade.dot(frente_ar)
		velocidade_lateral = velocidade.dot(direita_ar)
		angulo_derrapagem = atan2(velocidade_lateral, maxf(absf(velocidade_frente), 1.0))
		fazendo_drift = false
		esta_parado = velocidade.length() < limite_parado
		return

	direcao_atual = move_toward(direcao_atual, clampf(entrada_direcao, -1.0, 1.0), suavizacao_direcao * delta)

	var frente := Vector2.RIGHT.rotated(angulo)
	var direita := frente.orthogonal()
	var vel_frontal := velocidade.dot(frente)
	var vel_lateral := velocidade.dot(direita)

	if is_zero_approx(acelerador):
		vel_frontal = move_toward(vel_frontal, 0.0, desaceleracao_inercia * delta)
	else:
		vel_frontal += aceleracao * acelerador * delta

	if freio_mao:
		vel_frontal = move_toward(vel_frontal, 0.0, forca_freio_mao * delta)

	var vel_maxima_efetiva := velocidade_maxima * multiplicador_superficie
	if vel_frontal > vel_maxima_efetiva:
		vel_frontal = move_toward(vel_frontal, vel_maxima_efetiva, desaceleracao_fora_pista * delta)
	else:
		vel_frontal = clampf(vel_frontal, -velocidade_maxima_re, vel_maxima_efetiva)

	vel_frontal -= vel_frontal * arrasto * delta

	var aderencia_atual := aderencia_freio_mao if freio_mao else aderencia
	if tempo_oleo > 0.0:
		tempo_oleo = maxf(tempo_oleo - delta, 0.0)
		aderencia_atual = 0.35
		angulo = wrapf(angulo + sentido_giro_oleo * 2.2 * delta, -PI, PI)
	vel_lateral *= exp(-aderencia_atual * delta)

	velocidade = frente * vel_frontal + direita * vel_lateral

	var vel_absoluta := absf(vel_frontal)
	var resposta_direcao := clampf(vel_absoluta / velocidade_ref_curva, 0.0, 1.0)
	var perda_curva := 1.0 - reducao_curva_alta_vel * clampf(vel_absoluta / velocidade_maxima, 0.0, 1.0)
	var sentido := signf(vel_frontal)
	if is_zero_approx(sentido):
		sentido = 1.0

	var giro := direcao_atual * taxa_curva_maxima * resposta_direcao * perda_curva * sentido * delta
	angulo = wrapf(angulo + giro, -PI, PI)

	frente = Vector2.RIGHT.rotated(angulo)
	direita = frente.orthogonal()
	velocidade_frente = velocidade.dot(frente)
	velocidade_lateral = velocidade.dot(direita)
	angulo_derrapagem = atan2(velocidade_lateral, maxf(absf(velocidade_frente), 1.0))
	fazendo_drift = absf(velocidade_lateral) > limite_drift
	esta_parado = velocidade.length() < limite_parado
