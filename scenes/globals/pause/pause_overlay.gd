# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasLayer

const INTRO_SCENE := "res://scenes/quests/story_quests/spectral_code__story/0_intro/spectral_code__story_intro.tscn"

@onready var pause_menu: Control = %PauseMenu
@onready var resume_button: Button = %ResumeButton
@onready var options: Control = %Options


func _ready() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	var new_state := not get_tree().paused
	visible = new_state
	get_tree().paused = new_state

	if new_state:
		pause_menu.show()
		resume_button.grab_focus()


func _on_options_button_pressed() -> void:
	options.show()


func _on_options_back() -> void:
	pause_menu.show()
	resume_button.grab_focus()


func _on_resume_button_pressed() -> void:
	toggle_pause()


func _on_restart_button_pressed() -> void:
	toggle_pause()
	_restart_quest()


func _restart_quest() -> void:
	GameState.clear()
	SceneSwitcher.change_to_file_with_transition(
		INTRO_SCENE, ^"", Transition.Effect.FADE, Transition.Effect.FADE
	)
