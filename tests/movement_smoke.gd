extends SceneTree


var _failures: int = 0


func _initialize() -> void:
	var car_scene := load("res://scenes/car/car.tscn") as PackedScene
	var car_a := car_scene.instantiate() as Car
	var car_b := car_scene.instantiate() as Car
	_check("car models are per-instance", car_a.model != car_b.model)
	car_a.free()
	car_b.free()

	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main.tscn failed to load")
		_finish()
		return

	var main := packed.instantiate()
	root.add_child(main)
	await physics_frame
	await physics_frame

	var car := main.get_node_or_null("Car") as Car
	var camera := main.get_node_or_null("Camera") as Camera2D
	var highway := main.get_node_or_null("Highway") as Highway

	_check("main scene instantiates", main != null)
	_check("car node present", car != null)
	_check("car model present", car != null and car.model != null)
	_check("camera node present", camera != null)
	_check("highway node present", highway != null)
	if car == null or highway == null:
		_finish()
		return

	var sprite := car.get_node_or_null("Sprite2D") as Sprite2D
	_check("sprite offset applied",
			sprite != null and is_equal_approx(sprite.rotation, PI * 0.5))

	await physics_frame
	_check("car starts stationary", car.model.is_stationary)

	var on_road := highway.curve.sample_baked(3000.0)
	var tangent := (highway.curve.sample_baked(3020.0) - on_road).normalized()
	car.global_position = on_road
	car.model.heading = tangent.angle()
	car.model.velocity = Vector2.ZERO
	var start := car.global_position
	Input.action_press("throttle")
	for i in 90:
		await physics_frame
	Input.action_release("throttle")
	var travelled := car.global_position - start
	print("  travelled %.1f px, speed %.1f" % [travelled.length(), car.model.speed])
	_check("car moves under throttle", travelled.length() > 100.0)
	_check("car moves along its heading",
			travelled.normalized().dot(Vector2.RIGHT.rotated(car.model.heading)) > 0.95)
	_check("camera follows the car",
			camera.global_position.distance_to(car.global_position) < 400.0)

	var distance := highway.curve.get_closest_offset(car.global_position)
	var normal := (highway.curve.sample_baked(distance + 20.0)
			- highway.curve.sample_baked(distance)).normalized()
	car.model.heading = Vector2(-normal.y, normal.x).angle()
	car.model.velocity = Vector2.ZERO
	Input.action_press("throttle")
	for i in 180:
		await physics_frame
	Input.action_release("throttle")
	print("  speed after driving into the rock wall: %.1f" % car.model.speed)
	_check("collision bleeds off speed", car.model.speed < car.model.max_speed * 0.6)

	main.free()
	_finish()


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("  [ok]   %s" % label)
	else:
		_failures += 1
		print("  [FAIL] %s %s" % [label, detail])


func _fail(label: String) -> void:
	_failures += 1
	print("  [FAIL] %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("RESULT: all checks passed")
	else:
		print("RESULT: %d check(s) FAILED" % _failures)
	quit(1 if _failures > 0 else 0)
