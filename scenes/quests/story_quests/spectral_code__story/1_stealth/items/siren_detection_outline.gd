# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const RAY_COUNT := 28
const REFRESH_INTERVAL := 1.0 / 30.0
const FILL := Color(1.0, 0.77, 0.30, 0.23)
const EDGE := Color(1.0, 0.84, 0.43, 0.84)

@onready var _collider: CollisionPolygon2D = $"../CollisionPolygon2D"
@onready var _sight: RayCast2D = $"../../SightRayCast"
@onready var _light: PointLight2D = $"../Light"

var _cone := PackedVector2Array()
var _visible_polygons: Array[PackedVector2Array] = []
var _refresh_in := 0.0


func _ready() -> void:
	for point: Vector2 in _collider.polygon:
		_cone.append(_collider.transform * point)


func _physics_process(delta: float) -> void:
	_refresh_in -= delta
	if _refresh_in > 0.0:
		return
	_refresh_in = REFRESH_INTERVAL
	var screen_position := get_global_transform_with_canvas().origin
	var on_screen := get_viewport_rect().grow(300.0 * global_scale.length()).has_point(screen_position)
	if not on_screen or _collider.disabled or not _light.enabled or not _light.visible:
		if not _visible_polygons.is_empty():
			_visible_polygons.clear()
			queue_redraw()
		return

	_update_visible_cone()
	queue_redraw()


func _update_visible_cone() -> void:
	var origin := to_local(_sight.global_position)
	var first_angle := INF
	var last_angle := -INF
	var reach := 0.0
	for vertex: Vector2 in _cone:
		var direction := vertex - origin
		first_angle = minf(first_angle, direction.angle())
		last_angle = maxf(last_angle, direction.angle())
		reach = maxf(reach, direction.length())

	var sight_fan := PackedVector2Array([origin])
	var query := PhysicsRayQueryParameters2D.create(
		_sight.global_position, _sight.global_position, _sight.collision_mask, [owner.get_rid()]
	)
	query.collide_with_areas = _sight.collide_with_areas
	query.collide_with_bodies = _sight.collide_with_bodies
	query.hit_from_inside = _sight.hit_from_inside
	var space := get_world_2d().direct_space_state
	var occluded := false
	for index in RAY_COUNT + 1:
		var angle := lerpf(first_angle - 0.01, last_angle + 0.01, float(index) / RAY_COUNT)
		query.to = to_global(origin + Vector2.from_angle(angle) * (reach + 1.0))
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			sight_fan.append(to_local(query.to))
		else:
			sight_fan.append(to_local(hit.position))
			occluded = true

	if occluded:
		_visible_polygons = Geometry2D.intersect_polygons(_cone, sight_fan)
	else:
		_visible_polygons = [_cone]


func _draw() -> void:
	for polygon: PackedVector2Array in _visible_polygons:
		if polygon.size() < 3:
			continue
		draw_colored_polygon(polygon, FILL)
		var outline := polygon.duplicate()
		outline.append(outline[0])
		draw_polyline(outline, EDGE, 2.0, true)
