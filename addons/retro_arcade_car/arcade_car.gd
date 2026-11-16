class_name ArcadeCar
extends CharacterBody3D
## A low-poly arcade car for Godot 4: gas, brake, reverse, steering that only bites once
## the car rolls, a bounce off walls, and anything in front of the bumper at speed gets
## knocked flying. The nose points along +X. Drop it in a scene with a floor and drive.
##
## Free piece of the Retro Crime Sandbox Kit (MIT). Full kit: https://cs5475.itch.io/retro-crime-sandbox-kit

signal crashed(speed: float)                 # hit a wall or another car hard
signal knocked(body: Node3D, speed: float)   # hit something in the "knockable" group

@export var driven := true                   # read input; turn off for a parked or AI car
@export var build_box_body := true           # build the box car; turn off to use your own model
@export var color := Color(0.2, 0.45, 0.6)
@export var max_speed := 17.0                # metres per second
@export var reverse_speed := -6.0
@export var accel := 11.0
@export var brake := 26.0
@export var drag := 3.5
@export var turn_rate := 2.3                 # radians per second at full lock, once moving
@export var action_gas: StringName = &"ui_up"
@export var action_brake: StringName = &"ui_down"
@export var action_left: StringName = &"ui_left"
@export var action_right: StringName = &"ui_right"

var speed := 0.0      # along the nose; negative is reverse
var gas := 0.0        # -1..1, set these yourself when driven is false
var turn := 0.0       # -1..1, positive turns left
var _bump_t := 0.0
var _wheels: Array = []


func _ready() -> void:
	if build_box_body:
		_build_body()


func _part(size: Vector3, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	m.roughness = 1.0
	mi.material_override = m
	mi.position = pos
	add_child(mi)
	return mi


func _build_body() -> void:
	_part(Vector3(3.8, 0.7, 1.7), Vector3(0, 0.65, 0), color)
	_part(Vector3(2.0, 0.6, 1.5), Vector3(-0.2, 1.3, 0), color.darkened(0.15))
	_part(Vector3(1.9, 0.45, 1.52), Vector3(-0.2, 1.3, 0), Color(0.55, 0.7, 0.8))
	for x in [-1.25, 1.25]:
		for z in [-0.8, 0.8]:
			_wheels.append(_part(Vector3(0.6, 0.6, 0.25), Vector3(x, 0.32, z), Color(0.08, 0.08, 0.08)))
	for z in [-0.5, 0.5]:
		_part(Vector3(0.1, 0.18, 0.4), Vector3(1.91, 0.75, z), Color(1, 0.95, 0.7))
		_part(Vector3(0.1, 0.16, 0.36), Vector3(-1.91, 0.75, z * 1.1), Color(0.8, 0.1, 0.1))
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(3.8, 1.4, 1.7)
	col.shape = bs
	col.position = Vector3(0, 0.9, 0)  # a hand above the road, so the floor never counts as a crash
	add_child(col)


func nose() -> Vector3:
	return global_transform.basis.x


func _physics_process(delta: float) -> void:
	_bump_t = max(0.0, _bump_t - delta)
	if driven:
		gas = Input.get_axis(action_brake, action_gas)
		turn = Input.get_axis(action_right, action_left)
	if gas > 0.05:
		speed = move_toward(speed, max_speed * gas, (accel if speed >= 0.0 else brake) * delta)
	elif gas < -0.05:
		if speed > 0.5:
			speed = move_toward(speed, 0.0, brake * delta)
		else:
			speed = move_toward(speed, reverse_speed, accel * 0.6 * delta)
	else:
		speed = move_toward(speed, 0.0, drag * delta)
	# steering only bites once the car rolls, and flips in reverse like a real car
	var grip: float = clamp(absf(speed) / 6.0, 0.0, 1.0)
	rotation.y += turn * turn_rate * grip * signf(speed) * delta
	velocity = nose() * speed
	velocity.y = 0.0
	move_and_slide()
	var hit_wall := false
	for k in get_slide_collision_count():
		if absf(get_slide_collision(k).get_normal().y) < 0.5:
			hit_wall = true
	if hit_wall and absf(speed) > 5.0 and _bump_t <= 0.0:
		crashed.emit(absf(speed))
		speed *= -0.25
		_bump_t = 0.4
	elif hit_wall:
		speed *= 0.9
	for w in _wheels:
		w.rotation.z -= speed * delta * 3.0
	_knock()


# Anything in the "knockable" group in front of the bumper at speed gets knocked. Keep those
# bodies on a collision layer the car doesn't collide with, so it drives through them and this
# decides what happens. If the body has on_car_hit(dir, speed) it's called; a RigidBody3D just
# gets an impulse.
func _knock() -> void:
	if absf(speed) < 3.5:
		return
	for b in get_tree().get_nodes_in_group("knockable"):
		if not (b is Node3D) or b.get_meta("knocked_t", 0.0) > Time.get_ticks_msec() / 1000.0:
			continue
		var local := to_local(b.global_position)
		if absf(local.x) < 2.3 and absf(local.z) < 1.25 and absf(local.y) < 2.0:
			var away: Vector3 = b.global_position - global_position
			away.y = 0.0
			var dir: Vector3 = (nose() * signf(speed) + away.normalized() * 0.6).normalized()
			b.set_meta("knocked_t", Time.get_ticks_msec() / 1000.0 + 0.5)
			if b.has_method("on_car_hit"):
				b.on_car_hit(dir, absf(speed))
			elif b is RigidBody3D:
				b.apply_central_impulse((dir + Vector3.UP * 0.6) * absf(speed) * b.mass * 0.6)
			knocked.emit(b, absf(speed))
			speed *= 0.85
