extends Control

var item_id
var item_name
var item_description
var item_type
var stack_id
var stack_max_size
var stack_size

func _insert_item(num_to_insert):
	var leftover
	stack_size += num_to_insert
	leftover = stack_size - stack_max_size
	
	if leftover > 0:
		stack_size -= leftover
		return leftover
	else:
		return 0

func _remove_item():
	if stack_size > 0:
		stack_size -= 1