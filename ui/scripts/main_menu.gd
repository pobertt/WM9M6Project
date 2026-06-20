extends Control

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/level_select.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_controls_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/controls_menu.tscn")
