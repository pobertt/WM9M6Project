extends Control

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_tutorial_button_pressed() -> void:
		get_tree().change_scene_to_file("res://level/tutorial.tscn")


func _on_level_1_button_pressed() -> void:
	get_tree().change_scene_to_file("res://level/level1.tscn")


func _on_level_2_button_pressed() -> void:
	get_tree().change_scene_to_file("res://level/level2.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
