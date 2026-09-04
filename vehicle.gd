extends VehicleBody3D

@export var drive_force := 1600.0
@export var reverse_force := 900.0
@export var brake_force := 35.0
@export var max_steering_angle := 0.45

@onready var front_left_wheel: VehicleWheel3D = $FrontLeftWheel
@onready var front_right_wheel: VehicleWheel3D = $FrontRightWheel

func _physics_process(_delta: float) -> void:
	var throttle := 0.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		throttle += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		throttle -= 1.0

	var steering_input := Input.get_axis("ui_left", "ui_right")
	front_left_wheel.steering = steering_input * max_steering_angle
	front_right_wheel.steering = steering_input * max_steering_angle

	if throttle > 0.0:
		engine_force = throttle * drive_force
		brake = 0.0
	elif throttle < 0.0:
		engine_force = throttle * reverse_force
		brake = 0.0
	else:
		engine_force = 0.0
		brake = 0.0

	if Input.is_key_pressed(KEY_SPACE):
		brake = brake_force * 2.5
