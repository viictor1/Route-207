class_name CarModel
extends Resource


@export_group("Longitudinal")
@export var max_speed: float = 750.0
@export var reverse_max_speed: float = 2700.0
@export var acceleration: float = 500.0
@export var handbrake_brake: float = 500.0
@export var coast_deceleration: float = 90.0
@export var drag: float = 0.35

@export_group("Steering")
@export var max_turn_rate: float = 4
@export var turn_speed_ref: float = 150.0
@export var high_speed_turn_falloff: float = 0.65
@export var steer_smoothing: float = 9.0

@export_group("Grip")
@export var grip: float = 11.0
@export var handbrake_grip: float = 1.6

@export_group("State thresholds")
@export var drift_threshold: float = 260.0
@export var stationary_threshold: float = 14.0

var velocity: Vector2 = Vector2.ZERO
var heading: float = -PI * 0.5
var steer: float = 0.0

var speed: float = 0.0
var lateral_speed: float = 0.0
var slip_angle: float = 0.0
var is_drifting: bool = false
var is_stationary: bool = true


func step(throttle: float, steer_input: float, handbrake: bool, delta: float) -> void:
	steer = move_toward(steer, clampf(steer_input, -1.0, 1.0), steer_smoothing * delta)

	var forward := Vector2.RIGHT.rotated(heading)
	var right := forward.orthogonal()
	var forward_speed := velocity.dot(forward)
	var lateral := velocity.dot(right)

	if is_zero_approx(throttle):
		forward_speed = move_toward(forward_speed, 0.0, coast_deceleration * delta)
	else:
		forward_speed += acceleration * throttle * delta

	if handbrake:
		forward_speed = move_toward(forward_speed, 0.0, handbrake_brake * delta)

	forward_speed = clampf(forward_speed, -reverse_max_speed, max_speed)
	forward_speed -= forward_speed * drag * delta

	var grip_now := handbrake_grip if handbrake else grip
	lateral *= exp(-grip_now * delta)

	velocity = forward * forward_speed + right * lateral

	var abs_speed := absf(forward_speed)
	var authority := clampf(abs_speed / turn_speed_ref, 0.0, 1.0)
	var falloff := 1.0 - high_speed_turn_falloff * clampf(abs_speed / max_speed, 0.0, 1.0)
	var direction := signf(forward_speed)
	if is_zero_approx(direction):
		direction = 1.0
	var turn := steer * max_turn_rate * authority * falloff * direction * delta
	heading = wrapf(heading + turn, -PI, PI)

	forward = Vector2.RIGHT.rotated(heading)
	right = forward.orthogonal()
	speed = velocity.dot(forward)
	lateral_speed = velocity.dot(right)
	slip_angle = atan2(lateral_speed, maxf(absf(speed), 1.0))
	is_drifting = absf(lateral_speed) > drift_threshold
	is_stationary = velocity.length() < stationary_threshold
