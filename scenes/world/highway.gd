class_name Highway
extends Node2D


const PIXELS_PER_METER := 18.0

@export_group("Road shape")
@export var road_width: float = 560.0
@export var band_half_width: float = 1700.0
@export var wall_thickness: float = 300.0
@export var sample_step: float = 50.0

@export_group("Generation")
@export var chunk_length: float = 1000.0
@export var segment_length: float = 700.0
@export var max_curve_per_segment: float = 0.18
@export var max_heading_deviation: float = 0.75
@export var generate_ahead: float = 7000.0
@export var keep_behind: float = 2500.0
@export var start_offset: float = 800.0
@export var seed: int = 207

@export_group("Wiring")
@export var car_path: NodePath

var curve := Curve2D.new()
var distance_along: float = 0.0

var _rng := RandomNumberGenerator.new()
var _heading: float = 0.0
var _chunks: Dictionary = {}
var _car: Node2D
var _search_step := 50.0


func _ready() -> void:
	_rng.seed = seed
	curve.bake_interval = 20.0
	curve.add_point(Vector2(0.0, start_offset), Vector2.ZERO, Vector2.UP * segment_length * 0.4)
	if car_path != NodePath():
		_car = get_node_or_null(car_path) as Node2D
	if _car != null:
		distance_along = curve.get_closest_offset(_car.global_position)
	_ensure_length(start_offset + generate_ahead + chunk_length * 2.0)
	_stream()


func _physics_process(_delta: float) -> void:
	if _car == null:
		return
	_update_distance(_car.global_position)
	_stream()


func progress_km() -> float:
	return maxf(0.0, distance_along - start_offset) / PIXELS_PER_METER / 1000.0


func _append_segment() -> void:
	var last_index := curve.point_count - 1
	var last_point := curve.get_point_position(last_index)
	_heading = clampf(
		_heading + _rng.randf_range(-max_curve_per_segment, max_curve_per_segment),
		-max_heading_deviation,
		max_heading_deviation,
	)
	var direction := Vector2.UP.rotated(_heading)
	var handle := direction * segment_length * 0.4
	curve.set_point_out(last_index, handle)
	curve.add_point(last_point + direction * segment_length, -handle, handle)


func _ensure_length(target: float) -> void:
	while curve.get_baked_length() < target:
		_append_segment()


func _stream() -> void:
	var first := maxi(int(floor((distance_along - keep_behind) / chunk_length)), 0)
	var last := int(floor((distance_along + generate_ahead) / chunk_length))
	_ensure_length(float(last + 2) * chunk_length)

	for i in range(first, last + 1):
		if not _chunks.has(i):
			_chunks[i] = _build_chunk(i)

	for i in _chunks.keys():
		if i < first or i > last:
			(_chunks[i] as Node).queue_free()
			_chunks.erase(i)


func _build_chunk(chunk_index: int) -> RoadChunk:
	var start := float(chunk_index) * chunk_length
	var end := minf(start + chunk_length, curve.get_baked_length())
	var chunk := RoadChunk.create(curve, chunk_index, start, end, {
		"road_width": road_width,
		"band_half_width": band_half_width,
		"wall_thickness": wall_thickness,
		"sample_step": sample_step,
	})
	add_child(chunk)
	return chunk


func _update_distance(position: Vector2) -> void:
	var window := 500.0
	var total := curve.get_baked_length()
	var from := maxf(distance_along - window, 0.0)
	var to := minf(distance_along + window, total)

	var best := distance_along
	var best_distance := INF
	var sample := from
	while sample <= to:
		var candidate := position.distance_squared_to(curve.sample_baked(sample))
		if candidate < best_distance:
			best_distance = candidate
			best = sample
		sample += _search_step

	if is_equal_approx(best, from) or is_equal_approx(best, to):
		best = curve.get_closest_offset(position)
	distance_along = best
