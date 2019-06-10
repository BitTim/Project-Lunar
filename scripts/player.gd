extends KinematicBody2D

signal health_change
signal dead
signal placed
signal destroyed
signal dropped
signal show_resource_map
signal hide_resource_map
signal get_hud_node
signal chunk_change

export(int) var health
export(int) var speed
export(int) var acceleration
export(int) var drag
export(Vector2) var tile_size
export(int) var limit_top
export(int) var limit_bottom
export(int) var limit_left
export(int) var limit_right

var hud
var joystick
var hud_path = "MarginContainer/HBoxContainer/TouchControl/"
var touch_control = false
var velocity = Vector2()
var alive = true
var resource_map_opened = false
var curr_chunk = Vector2(0, 0)
var prev_chunk = Vector2(0, 0)

func _ready():
	emit_signal("get_hud_node")

func input():
	if Input.is_action_pressed("right") and velocity.x <= speed:
		velocity += Vector2(acceleration, 0)
	if Input.is_action_pressed("left") and velocity.x >= -speed:
		velocity -= Vector2(acceleration, 0)
	if Input.is_action_pressed("up") and velocity.y >= -speed:
		velocity -= Vector2(0, acceleration)
	if Input.is_action_pressed("down") and velocity.y <= speed:
		velocity += Vector2(0, acceleration)
	
	if Input.is_action_just_pressed("show_resource_map"):
		if resource_map_opened == false:
			resource_map_opened = true
			emit_signal("show_resource_map")
		else:
			resource_map_opened = false
			emit_signal("hide_resource_map")
	
	if touch_control:
		velocity += joystick._get_value() * speed

func move():
	# Apply drag
	if velocity.x > 0:
		velocity.x -= drag
	if velocity.x < 0:
		velocity.x += drag
	if velocity.y > 0:
		velocity.y -= drag
	if velocity.y < 0:
		velocity.y += drag
	
	# Clamp small values to 0
	if (velocity.x < drag and velocity.x > -drag):
		velocity.x = 0
	if (velocity.y < drag and velocity.y > -drag):
		velocity.y = 0
	
	# Map Borders
	if (position.x > (limit_right - 1) * tile_size.x):
		position.x = (limit_right - 1) * tile_size.x
	if (position.x < limit_left * tile_size.x):
		position.x = limit_left * tile_size.x
	if (position.y > (limit_bottom - 2) * tile_size.y):
		position.y = (limit_bottom - 2) * tile_size.y
	if (position.y < limit_top * tile_size.y):
		position.y = limit_top * tile_size.y
	
	# Max speed
	if velocity.x > speed:
		velocity.x = speed
	if velocity.x < -speed:
		velocity.x = -speed
	if velocity.y > speed:
		velocity.y = speed
	if velocity.y < -speed:
		velocity.y = -speed
	
func _physics_process(delta):
	if not alive:
		return
	
	if hud != null:
		if hud.get_node(hud_path).visible == true:
			touch_control = true
			joystick = hud.get_node(hud_path + "Joystick/JoystickButton")
	else:
		emit_signal("get_hud_node")
		
	input()
	move()
	move_and_slide(velocity)
	curr_chunk = Vector2(int(position.x / tile_size.x / 32), int(position.y / tile_size.y / 32))
	if curr_chunk != prev_chunk:
		emit_signal("chunk_change")
	prev_chunk = curr_chunk