extends Control

func _ready():
	var button = $Button
	button.connect("pressed", self, "_on_button_pressed", [$Button.scene_to_load])

func _on_button_pressed(scene_to_load):
	get_tree().change_scene(scene_to_load)