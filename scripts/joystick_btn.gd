extends TouchScreenButton

export(Vector2) var radius = Vector2(32, 32)
export(int) var boundary = 64
export(int) var return_acceleration = 20
export(int) var threshold = 10

var current_drag = -1

func _process(delta):
	if current_drag == -1:
		var pos_diff = (Vector2(0, 0) - radius) - position
		position += pos_diff * return_acceleration * delta

func _get_button_pos():
	return position + radius

func _input(event):
	if event is InputEventScreenDrag or (event is InputEventScreenTouch and event.is_pressed()):
		var event_dist_from_centre = (event.position - get_parent().global_position).length()

		if event_dist_from_centre <= boundary * global_scale.x or event.get_index() == current_drag:
			set_global_position(event.position - radius * global_scale)

			if _get_button_pos().length() > boundary:
				set_position(_get_button_pos().normalized() * boundary - radius)

			current_drag = event.get_index()

	if event is InputEventScreenTouch and !event.is_pressed() and event.get_index() == current_drag:
		current_drag = -1

func _get_value():
	if _get_button_pos().length() > threshold:
		return _get_button_pos().normalized()
	return Vector2(0, 0)