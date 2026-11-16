extends Node3D
## A parking lot to drive the ArcadeCar around: walls to bounce off and crates to knock over.
## Arrows or WASD to drive. Everything is built here in code.

var car: ArcadeCar
var cam: Camera3D


func _ready() -> void:
	# WASD as well as the arrows
	for pair in [[&"ui_up", KEY_W], [&"ui_down", KEY_S], [&"ui_left", KEY_A], [&"ui_right", KEY_D]]:
		var ev := InputEventKey.new()
		ev.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0], ev)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.32, 0.27, 0.4)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.52, 0.62)
	env.fog_enabled = true
	env.fog_light_color = Color(0.32, 0.27, 0.4)
	env.fog_density = 0.02
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	add_child(sun)
	_box(Vector3(80, 1, 80), Vector3(0, -0.5, 0), Color(0.24, 0.24, 0.27))
	for e in [-1, 1]:
		_box(Vector3(1, 2, 60), Vector3(e * 30.0, 1, 0), Color(0.5, 0.3, 0.25))
		_box(Vector3(60, 2, 1), Vector3(0, 1, e * 30.0), Color(0.5, 0.3, 0.25))
	for i in 18:
		_crate(Vector3(randf_range(-24, 24), 0.5, randf_range(-24, 24)))
	car = ArcadeCar.new()
	add_child(car)
	car.position = Vector3(0, 0, 0)
	cam = Camera3D.new()
	add_child(cam)
	cam.fov = 52.0


func _box(size: Vector3, pos: Vector3, c: Color) -> void:
	var sb := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	col.shape = bs
	sb.add_child(col)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	mi.material_override = m
	sb.add_child(mi)
	sb.position = pos
	add_child(sb)


# Crates sit on layer 2, which the car doesn't collide with, so it drives into them and
# ArcadeCar._knock() sends them flying.
func _crate(pos: Vector3) -> void:
	var rb := RigidBody3D.new()
	rb.collision_layer = 2
	rb.collision_mask = 1 | 2
	rb.mass = 2.0
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3.ONE
	col.shape = bs
	rb.add_child(col)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.6, 0.42, 0.25)
	mi.material_override = m
	rb.add_child(mi)
	rb.position = pos
	rb.add_to_group("knockable")
	add_child(rb)


var t := 0.0


func _process(delta: float) -> void:
	# --autodrive: the car drives itself in loops (for screenshots and a quick look)
	if "--autodrive" in OS.get_cmdline_user_args():
		t += delta
		car.driven = false
		car.gas = 1.0
		car.turn = 0.55 * sin(t * 0.9)
		var at: Vector3 = car.global_position
		if absf(at.x) > 18.0 or absf(at.z) > 18.0:
			# near a wall: steer back toward the middle of the lot
			var to := (-at).normalized()
			var fwd := car.nose()
			car.turn = clamp(atan2(fwd.cross(to).y, fwd.dot(to)) * 2.5, -1.0, 1.0)
	# a high three-quarter view that slides with the car and looks ahead of it
	var ahead: Vector3 = car.nose() * car.speed * 0.35
	var target: Vector3 = car.global_position + ahead + Vector3(0, 15.0, 6.8)
	cam.global_position = cam.global_position.lerp(target, 1.0 - exp(-4.0 * delta))
	cam.look_at(cam.global_position + Vector3(0, -15.0, -6.8) + Vector3(0, 0.8, -0.8))
