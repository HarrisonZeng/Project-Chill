extends CharacterBody2D

class_name PlayerController

@export var move_speed := 220.0

var controls_enabled := true
var last_move_direction := Vector2.DOWN

@onready var visual: Polygon2D = $Visual
@onready var shadow: Polygon2D = $Shadow


func _ready() -> void:
	add_to_group("player")


func _physics_process(_delta: float) -> void:
	if not controls_enabled:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction != Vector2.ZERO:
		last_move_direction = input_direction

	velocity = input_direction * move_speed
	move_and_slide()
	_update_visuals(input_direction)


func set_controls_enabled(value: bool) -> void:
	controls_enabled = value
	if not controls_enabled:
		velocity = Vector2.ZERO


func _update_visuals(input_direction: Vector2) -> void:
	if input_direction.x != 0.0:
		visual.scale.x = -1.0 if input_direction.x < 0.0 else 1.0

	var leaning := 1.0 + min(input_direction.length(), 1.0) * 0.08
	shadow.scale = Vector2(leaning, leaning)
