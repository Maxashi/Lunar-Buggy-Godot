extends Camera3D
## Mouse-orbit camera with damped follow and speed-based FOV.
## Attach to a Camera3D that is a child of the target (or set `target`).

@export var target: Node3D
@export var distance := 7.5
@export var height_offset := 1.5
@export var mouse_sensitivity := 0.003
@export var min_pitch := deg_to_rad(-60.0)
@export var max_pitch := deg_to_rad(80.0)
@export var follow_smoothing := 6.0

@export_group("Field of view")
@export var base_fov := 70.0
@export var max_fov := 100.0
@export var max_fov_speed := 40.0
@export var fov_smoothing := 4.0

@export_group("Auto align")
@export var align_min_speed := 8.0
@export var align_full_speed := 25.0
@export var align_rate := 2.5
## Seconds after mouse movement before auto-align resumes.
@export var align_delay := 1.0
## Target's local forward direction (the buggy drives toward +Z).
@export var forward_local := Vector3.BACK

var _idle_time := 0.0
var _yaw := PI
var _pitch := deg_to_rad(15.0)
var _focus := Vector3.ZERO
var _last_target_pos := Vector3.ZERO

func _ready() -> void:
	if target == null:
		target = get_parent() as Node3D
	# Detach from the target's transform so we control the motion ourselves.
	top_level = true
	_focus = target.global_position
	_last_target_pos = _focus
	fov = base_fov
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_idle_time = 0.0
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch = clampf(_pitch + event.relative.y * mouse_sensitivity, min_pitch, max_pitch)
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if target == null:
		return

	var target_pos := target.global_position
	var velocity := (target_pos - _last_target_pos) / delta
	var speed := velocity.length()
	_last_target_pos = target_pos

	_idle_time += delta
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	var moving_forward := flat.dot(target.global_basis * forward_local) > 0.0
	if _idle_time > align_delay and moving_forward and flat.length() > 0.001:
		var weight := smoothstep(align_min_speed, align_full_speed, flat.length())
		var heading := atan2(-flat.x, -flat.z)
		_yaw = lerp_angle(_yaw, heading, 1.0 - exp(-align_rate * weight * delta))

	# Frame-rate independent exponential damping.
	_focus = _focus.lerp(target_pos + Vector3.UP * height_offset, 1.0 - exp(-follow_smoothing * delta))

	var orbit := Basis.from_euler(Vector3(-_pitch, _yaw, 0.0))
	global_transform = Transform3D(orbit, _focus + orbit * Vector3(0.0, 0.0, distance))

	var fov_target := lerpf(base_fov, max_fov, clampf(speed / max_fov_speed, 0.0, 1.0))
	fov = lerpf(fov, fov_target, 1.0 - exp(-fov_smoothing * delta))
