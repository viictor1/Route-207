class_name RoadChunk
extends Node2D


const EDGE_LINE_WIDTH := 10.0
const CENTER_LINE_WIDTH := 12.0
const DASH_PERIOD := 150.0
const DASH_LENGTH := 70.0

const EDGE_LINE_COLOR := Color(0.72, 0.72, 0.68, 0.55)
const CENTER_LINE_COLOR := Color(0.78, 0.74, 0.55, 0.62)

var index: int = 0


static func create(curve: Curve2D, chunk_index: int, start: float, end: float,
		config: Dictionary) -> RoadChunk:
	var chunk := RoadChunk.new()
	chunk.index = chunk_index
	chunk._build(curve, start, end, config)
	return chunk


func _build(curve: Curve2D, start: float, end: float, config: Dictionary) -> void:
	var road_half: float = config.road_width * 0.5
	var band_half: float = config.band_half_width
	var wall_thickness: float = config.wall_thickness
	var sample_step: float = config.sample_step
	var total_length := curve.get_baked_length()

	var origin := curve.sample_baked(start)
	position = origin
	var uv_offset := Vector2(
		fposmod(origin.x, float(ProceduralTextures.SIZE)),
		fposmod(origin.y, float(ProceduralTextures.SIZE)),
	)

	var centers := PackedVector2Array()
	var normals := PackedVector2Array()
	var sample_count := int(ceil((end - start) / sample_step)) + 1
	for i in sample_count:
		var distance := minf(start + float(i) * sample_step, end)
		var point := curve.sample_baked(distance)
		var ahead := curve.sample_baked(minf(distance + 2.0, total_length))
		var tangent := ahead - point
		if tangent.length_squared() < 0.000001:
			tangent = Vector2.UP
		tangent = tangent.normalized()
		centers.append(point - origin)
		normals.append(Vector2(-tangent.y, tangent.x))

	var road_a := _offset(centers, normals, road_half)
	var road_b := _offset(centers, normals, -road_half)
	var band_a := _offset(centers, normals, band_half)
	var band_b := _offset(centers, normals, -band_half)
	var wall_a := _offset(centers, normals, band_half + wall_thickness)
	var wall_b := _offset(centers, normals, -band_half - wall_thickness)

	_add_textured_strip(_strip(road_a, band_a), ProceduralTextures.dirt(), uv_offset)
	_add_textured_strip(_strip(road_b, band_b), ProceduralTextures.dirt(), uv_offset)
	var shoulder_a := _offset(centers, normals, road_half + 170.0)
	var shoulder_b := _offset(centers, normals, -road_half - 170.0)
	var worn := Color(0.74, 0.72, 0.68)
	_add_textured_strip(_strip(road_a, shoulder_a), ProceduralTextures.dirt(), uv_offset, worn)
	_add_textured_strip(_strip(road_b, shoulder_b), ProceduralTextures.dirt(), uv_offset, worn)
	_add_textured_strip(_strip(road_a, road_b), ProceduralTextures.asphalt(), uv_offset)
	_add_solid_strip(_strip(_offset(centers, normals, road_half - EDGE_LINE_WIDTH), road_a),
			EDGE_LINE_COLOR)
	_add_solid_strip(_strip(road_b, _offset(centers, normals, -road_half + EDGE_LINE_WIDTH)),
			EDGE_LINE_COLOR)
	_add_center_dashes(centers, normals, sample_step)
	_add_textured_strip(_strip(band_a, wall_a), ProceduralTextures.rock(), uv_offset)
	_add_textured_strip(_strip(band_b, wall_b), ProceduralTextures.rock(), uv_offset)

	var static_body := StaticBody2D.new()
	static_body.collision_layer = CollisionLayers.WORLD
	static_body.collision_mask = 0
	add_child(static_body)
	_add_wall_colliders(static_body, band_a, normals, 1.0, wall_thickness)
	_add_wall_colliders(static_body, band_b, normals, -1.0, wall_thickness)
	_add_props(static_body, centers, normals, road_half, band_half)


func _offset(points: PackedVector2Array, normals: PackedVector2Array,
		distance: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	result.resize(points.size())
	for i in points.size():
		result[i] = points[i] + normals[i] * distance
	return result


func _strip(side_a: PackedVector2Array, side_b: PackedVector2Array) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	polygon.append_array(side_a)
	for i in range(side_b.size() - 1, -1, -1):
		polygon.append(side_b[i])
	return polygon


func _add_polygon(points: PackedVector2Array) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.polygon = points
	add_child(polygon)
	return polygon


func _add_textured_strip(points: PackedVector2Array, texture: Texture2D,
		uv_offset: Vector2, tint: Color = Color.WHITE) -> void:
	var polygon := _add_polygon(points)
	polygon.texture = texture
	polygon.color = tint
	polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var uvs := PackedVector2Array()
	uvs.resize(points.size())
	for i in points.size():
		uvs[i] = points[i] + uv_offset
	polygon.uv = uvs


func _add_solid_strip(points: PackedVector2Array, color: Color) -> void:
	var polygon := _add_polygon(points)
	polygon.color = color


func _add_center_dashes(centers: PackedVector2Array, normals: PackedVector2Array,
		sample_step: float) -> void:
	for i in centers.size() - 1:
		var along := float(i) * sample_step
		if fposmod(along, DASH_PERIOD) > DASH_LENGTH:
			continue
		var a := centers[i]
		var b := centers[i + 1]
		var normal := normals[i] * (CENTER_LINE_WIDTH * 0.5)
		_add_solid_strip(PackedVector2Array([
			a - normal, b - normal, b + normal, a + normal,
		]), CENTER_LINE_COLOR)


func _add_wall_colliders(body: StaticBody2D, edge: PackedVector2Array,
		normals: PackedVector2Array, outward: float, thickness: float) -> void:
	for i in edge.size() - 1:
		var a := edge[i]
		var b := edge[i + 1]
		var segment := b - a
		var length := segment.length()
		if length < 1.0:
			continue
		var shape := RectangleShape2D.new()
		shape.size = Vector2(length + 10.0, thickness)
		var collider := CollisionShape2D.new()
		collider.shape = shape
		collider.position = (a + b) * 0.5 + normals[i] * outward * (thickness * 0.5)
		collider.rotation = segment.angle()
		body.add_child(collider)


func _add_props(body: StaticBody2D, centers: PackedVector2Array,
		normals: PackedVector2Array, road_half: float, band_half: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 207 * 7919 + index

	var inner := road_half + 90.0
	var outer := band_half - 70.0
	if outer <= inner:
		return

	for i in rng.randi_range(5, 9):
		var sample_index := rng.randi_range(0, centers.size() - 1)
		var lateral := rng.randf_range(inner, outer) * (1.0 if rng.randf() < 0.5 else -1.0)
		var radius := rng.randf_range(22.0, 46.0)
		_add_rock(body, centers[sample_index] + normals[sample_index] * lateral, radius, rng)


func _add_rock(body: StaticBody2D, at: Vector2, radius: float,
		rng: RandomNumberGenerator) -> void:
	var points := PackedVector2Array()
	var segments := rng.randi_range(7, 9)
	for i in segments:
		var angle := TAU * float(i) / float(segments)
		var r := radius * rng.randf_range(0.78, 1.12)
		points.append(Vector2(cos(angle), sin(angle)) * r)

	var outline := _add_polygon(points)
	outline.position = at
	outline.color = Color(0.10, 0.10, 0.12, 0.55)
	outline.scale = Vector2(1.18, 1.18)

	var polygon := _add_polygon(points)
	polygon.position = at
	polygon.texture = ProceduralTextures.rock()
	polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var uvs := PackedVector2Array()
	uvs.resize(points.size())
	for i in points.size():
		uvs[i] = points[i] + at
	polygon.uv = uvs

	var collider := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius * 0.9
	collider.shape = circle
	collider.position = at
	body.add_child(collider)
