# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control


func _ready() -> void:
	%Replay.grab_focus()


func _on_replay_pressed() -> void:
	GameState.clear()
	SceneSwitcher.change_to_file_with_transition(
		"res://scenes/quests/story_quests/spectral_code__story/0_intro/spectral_code__story_intro.tscn", ^"", Transition.Effect.FADE, Transition.Effect.FADE
	)
