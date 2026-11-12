extends SceneTree


const DELTA := 1.0 / 60.0

var _failures: int = 0


func _init() -> void:
	print("=== CarModel simulation (dt = %.4f) ===" % DELTA)

	_test_top_speed()
	_test_turning_direction()
	_test_handbrake_drift()
	_test_coast_to_stop()
	_test_reverse()

	print("")
	if _failures == 0:
		print("RESULT: all checks passed")
	else:
		print("RESULT: %d check(s) FAILED" % _failures)
	quit(1 if _failures > 0 else 0)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("  [ok]   %s" % label)
	else:
		_failures += 1
		print("  [FAIL] %s %s" % [label, detail])


func _test_top_speed() -> void:
	print("\n-- top speed (full throttle, straight) --")
	var car := CarModel.new()
	var t := 0.0
	for i in 300:
		car.step(1.0, 0.0, false, DELTA)
		t += DELTA
		if i % 30 == 29:
			print("  t=%4.1fs  speed=%7.1f  pos-speed=%7.1f" % [t, car.speed, car.velocity.length()])
	_check("reaches near max speed",
			car.speed > car.max_speed * 0.95,
			"(got %.1f, want >%.1f)" % [car.speed, car.max_speed * 0.95])
	_check("does not exceed max speed", car.speed <= car.max_speed + 0.01)
	_check("not drifting in a straight line", not car.is_drifting)
	_check("not stationary at speed", not car.is_stationary)


func _test_turning_direction() -> void:
	print("\n-- steady-state cornering (full throttle, full right) --")
	var car := CarModel.new()
	for i in 120:
		car.step(1.0, 0.0, false, DELTA)
	var heading_before := car.heading
	var steady_lateral := 0.0
	var steady_drifted := false
	for i in 240:
		car.step(1.0, 1.0, false, DELTA)
		if i >= 120:
			steady_lateral = maxf(steady_lateral, absf(car.lateral_speed))
			steady_drifted = steady_drifted or car.is_drifting
		if i % 20 == 19:
			print("  lateral=%7.1f  slip=%5.1fdeg  drift=%s"
					% [car.lateral_speed, rad_to_deg(car.slip_angle), car.is_drifting])
	_check("steering right increases heading", car.heading > heading_before)
	_check("cornering generates lateral slip", steady_lateral > 20.0)
	_check("steady-state cornering is NOT drifting", not steady_drifted,
			"(peak %.1f, threshold %.1f)" % [steady_lateral, car.drift_threshold])


func _test_handbrake_drift() -> void:
	print("\n-- handbrake drift (full throttle + full steer + handbrake) --")
	var car := CarModel.new()
	for i in 120:
		car.step(1.0, 0.0, false, DELTA)
	var peak_lateral := 0.0
	var drifted := false
	for i in 90:
		car.step(0.6, 1.0, true, DELTA)
		peak_lateral = maxf(peak_lateral, absf(car.lateral_speed))
		drifted = drifted or car.is_drifting
		if i % 15 == 14:
			print("  speed=%7.1f  lateral=%7.1f  drift=%s"
					% [car.speed, car.lateral_speed, car.is_drifting])
	print("  peak lateral=%.1f" % peak_lateral)
	_check("handbrake triggers the drifting state", drifted)
	_check("drift is substantial", peak_lateral > car.drift_threshold * 1.5,
			"(peak %.1f, threshold %.1f)" % [peak_lateral, car.drift_threshold])


func _test_coast_to_stop() -> void:
	print("\n-- coast to stop --")
	var car := CarModel.new()
	for i in 180:
		car.step(1.0, 0.0, false, DELTA)
	var t := 0.0
	while t < 6.0 and not car.is_stationary:
		car.step(0.0, 0.0, false, DELTA)
		t += DELTA
	print("  stopped after %.2fs" % t)
	_check("car coasts to a stop", car.is_stationary, "(speed %.2f)" % car.speed)
	_check("stop happens within 6s", t < 6.0)


func _test_reverse() -> void:
	print("\n-- reverse --")
	var car := CarModel.new()
	for i in 120:
		car.step(-1.0, 0.0, false, DELTA)
	print("  speed=%7.1f  velocity=(%.1f, %.1f)" % [car.speed, car.velocity.x, car.velocity.y])
	_check("reverse moves backwards along heading", car.speed < -1.0)
	_check("reverse is speed capped", car.speed >= -car.reverse_max_speed - 0.01)
