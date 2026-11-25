# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const NO_FINGER := -1
const MOUSE_FINGER := -2
const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]
const PANEL := Color("#191c25d9")
const INK := Color("#fff4d1")
const STITCH := Color("#dcc795")

var enabled := false

var _mouse_preview := false
var _orientation_blocked := false
var _resume_after_rotation := false
var _move_finger := NO_FINGER
var _action_finger := NO_FINGER
var _run_finger := NO_FINGER
var _move := Vector2.ZERO
var _strengths := Vector4.ZERO
var _stick_center := Vector2.ZERO
var _action_center := Vector2.ZERO
var _run_center := Vector2.ZERO
var _pause_center := Vector2.ZERO
var _unit := 1.0

@onready var _orientation_gate: CanvasLayer = $"../OrientationGate"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	enabled = DisplayServer.is_touchscreen_available()
	if OS.has_feature("web"):
		var window := JavaScriptBridge.get_interface("window")
		_mouse_preview = bool(window.yukeTouchPreview)
		enabled = bool(window.yukeTouchGame)
	get_viewport().size_changed.connect(_layout)
	get_window().focus_exited.connect(_release_inputs)
	_layout()
	hide()
	set_process(enabled)
	set_process_input(enabled)


func _layout() -> void:
	var area := get_viewport_rect().size
	_unit = minf(area.x, area.y) / 720.0
	_stick_center = Vector2(142.0, area.y / _unit - 144.0) * _unit
	_action_center = Vector2(area.x / _unit - 106.0, area.y / _unit - 119.0) * _unit
	_run_center = _action_center + Vector2(-93.0, -100.0) * _unit
	_pause_center = Vector2(65.0, 65.0) * _unit
	_release_inputs()
	_update_orientation(enabled and area.y > area.x)
	queue_redraw()


func _update_orientation(blocked: bool) -> void:
	if blocked == _orientation_blocked:
		return
	_orientation_blocked = blocked
	_orientation_gate.visible = blocked and not OS.has_feature("web")
	if blocked:
		_resume_after_rotation = not get_tree().paused
		get_tree().paused = true
	elif _resume_after_rotation:
		get_tree().paused = false


func _process(_delta: float) -> void:
	var show_controls := (
		not get_tree().paused and not Transitions.is_running()
		and not get_tree().has_group(&"dialogue_balloon")
		and get_tree().has_group(&"player")
	)
	if show_controls == visible:
		return
	visible = show_controls
	if not visible:
		_release_inputs()


func _input(event: InputEvent) -> void:
	if _orientation_blocked:
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return

	var handled := false
	if event is InputEventScreenTouch:
		handled = _begin_touch(event.index, event.position) if event.pressed and not event.canceled else _end_touch(event.index)
	elif event is InputEventScreenDrag and event.index == _move_finger:
		_update_move(event.position)
		handled = true
	elif _mouse_preview and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			handled = _begin_touch(MOUSE_FINGER, event.position) if event.pressed else _end_touch(MOUSE_FINGER)
		elif event is InputEventMouseMotion and _move_finger == MOUSE_FINGER:
			_update_move(event.position)
			handled = true

	if handled:
		get_viewport().set_input_as_handled()


func _begin_touch(finger: int, point: Vector2) -> bool:
	if point.distance_to(_pause_center) <= 42.0 * _unit:
		PauseOverlay.toggle_pause.call_deferred()
	elif _move_finger == NO_FINGER and point.distance_to(_stick_center) <= 110.0 * _unit:
		_move_finger = finger
		_update_move(point)
	elif _action_finger == NO_FINGER and point.distance_to(_action_center) <= 67.0 * _unit:
		_action_finger = finger
		_set_action_key(true)
	elif _run_finger == NO_FINGER and point.distance_to(_run_center) <= 49.0 * _unit:
		_run_finger = finger
		_send_action(&"running", 1.0)
	else:
		return false
	queue_redraw()
	return true


func _end_touch(finger: int) -> bool:
	if finger == _move_finger:
		_move_finger = NO_FINGER
		_set_move(Vector2.ZERO)
	elif finger == _action_finger:
		_action_finger = NO_FINGER
		_set_action_key(false)
	elif finger == _run_finger:
		_run_finger = NO_FINGER
		_send_action(&"running", 0.0)
	else:
		return false
	queue_redraw()
	return true


func _release_inputs() -> void:
	for finger: int in [_move_finger, _action_finger, _run_finger]:
		if finger != NO_FINGER:
			_end_touch(finger)


func _update_move(point: Vector2) -> void:
	var direction := (point - _stick_center) / (66.0 * _unit)
	var magnitude := clampf((direction.length() - 0.14) / 0.86, 0.0, 1.0)
	_set_move(direction.normalized() * magnitude)
	queue_redraw()


func _set_move(value: Vector2) -> void:
	_move = value
	var strengths := Vector4(
		maxf(-value.x, 0.0), maxf(value.x, 0.0), maxf(-value.y, 0.0), maxf(value.y, 0.0)
	)
	for index in MOVE_ACTIONS.size():
		var strength := snappedf(strengths[index], 0.05)
		if not is_equal_approx(strength, _strengths[index]):
			_strengths[index] = strength
			_send_action(MOVE_ACTIONS[index], strength)


func _send_action(action: StringName, strength: float) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = strength > 0.0
	event.strength = strength
	Input.parse_input_event(event)


func _set_action_key(pressed: bool) -> void:
	# Space is the existing context action for talking, puzzles and combat.
	var event := InputEventKey.new()
	event.device = 9
	event.physical_keycode = KEY_SPACE
	event.pressed = pressed
	Input.parse_input_event(event)


func _draw() -> void:
	_draw_button(_stick_center, 97.0, "", false)
	var knob := _stick_center + _move * 62.0 * _unit
	draw_circle(knob, 37.0 * _unit, STITCH, true, -1.0, true)
	draw_circle(knob, 31.0 * _unit, Color("#665148"), true, -1.0, true)
	_draw_button(_action_center, 64.0, "Acción", _action_finger != NO_FINGER)
	_draw_button(_run_center, 47.0, "Correr", _run_finger != NO_FINGER)
	_draw_button(_pause_center, 40.0, "", false)
	for offset: float in [-7.0, 7.0]:
		var start := _pause_center + Vector2(offset, -12.0) * _unit
		draw_line(start, start + Vector2(0.0, 24.0) * _unit, INK, 4.0 * _unit, true)


func _draw_button(center: Vector2, radius: float, title: String, pressed: bool) -> void:
	draw_circle(center, radius * _unit, Color("#6d513b") if pressed else PANEL, true, -1.0, true)
	draw_arc(center, (radius - 2.0) * _unit, 0.0, TAU, 48, STITCH, 2.0 * _unit, true)
	if title.is_empty():
		return
	var font := ThemeDB.fallback_font
	var font_size := roundi(23.0 * _unit)
	var text_width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline := (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	draw_string(font, center + Vector2(-text_width * 0.5, baseline), title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, INK)
