extends RigidBody2D




# MIT License
# -----------------------------------------------------------------------
#                       This file is part of:                           
#                     GODOT Polygon 2D Fracture                         
#           https://github.com/SoloByte/godot-polygon2d-fracture          
# -----------------------------------------------------------------------
# Copyright (c) 2021 David Grueneis
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.




export(Vector2) var rand_linear_velocity_range = Vector2(750.0, 1000.0)
#export(Vector2) var rand_angular_velocity_range = Vector2(-10.0, 10.0)
export(float) var radius : float = 250.0
export(int, 0, 5, 1) var smoothing : int = 1

export(bool) var placed_in_level : bool = false
export(bool) var randomize_texture_properties : bool = true
export(Texture) var poly_texture
export(Vector2) var regeneration_interval_range = Vector2.ZERO
export(float) var regeneration_amount : float = 10.0
export(float, 0.0, 1.0) var heal_treshold : float = 0.8




onready var _polygon2d := $Polygon2D
onready var _line2d := $Polygon2D/Line2D
onready var _col_polygon2d := $CollisionPolygon2D
onready var _rng := RandomNumberGenerator.new()

var regeneration_timer : Timer = null
var regeneration_started : bool = false

var polygon_restorer : PolygonRestorer = null

var start_poly : PoolVector2Array
var cur_area : float = 0.0
var start_area : float = 0.0
var total_frame_heal_amount : float = 0.0
export(float, 0.0, 1.0) var regeneration_start_threshold : float = 0.5



func _ready() -> void:
	_rng.randomize()
	if placed_in_level:
		var poly = PolygonLib.createCirclePolygon(radius, smoothing)
		setPolygon(poly)
		start_poly = poly
		start_area = PI * radius * radius
		
		linear_velocity = Vector2.RIGHT.rotated(PI * 2.0 * _rng.randf()) * _rng.randf_range(rand_linear_velocity_range.x, rand_linear_velocity_range.y)
		
		_polygon2d.texture = poly_texture
		if randomize_texture_properties:
			var rand_scale : float = _rng.randf_range(0.5, 2.0)
			_polygon2d.texture_scale = Vector2(rand_scale, rand_scale)
			_polygon2d.texture_rotation = _rng.randf_range(0.0, PI * 2.0)
			_polygon2d.texture_offset = Vector2(_rng.randf_range(-500, 500), _rng.randf_range(-500, 500))
		
		if regeneration_interval_range != Vector2.ZERO:
			var timer := Timer.new()
			add_child(timer)
			timer.one_shot = true
			timer.autostart = false
			timer.connect("timeout", self, "On_Regeneration_Timer_Timeout")
			regeneration_timer = timer



func getGlobalRotPolygon() -> float:
	return _polygon2d.global_rotation

func setPolygon(poly : PoolVector2Array) -> void:
	_polygon2d.set_polygon(poly)
	_col_polygon2d.set_polygon(poly)
	poly.append(poly[0])
	_line2d.points = poly


func setTexture(texture_info : Dictionary) -> void:
	_polygon2d.texture = texture_info.texture
	_polygon2d.texture_scale = texture_info.scale
	_polygon2d.texture_offset = texture_info.offset
	_polygon2d.texture_rotation = texture_info.rot


func getTextureInfo() -> Dictionary:
	return {"texture" : _polygon2d.texture, "rot" : _polygon2d.texture_rotation, "offset" : _polygon2d.texture_offset, "scale" : _polygon2d.texture_scale}


func getPolygon() -> PoolVector2Array:
	return _polygon2d.get_polygon()


func get_polygon() -> PoolVector2Array:
	return getPolygon()

func set_polygon(poly : PoolVector2Array) -> void:
	setPolygon(poly)

func On_Regeneration_Timer_Timeout() -> void:
	heal(regeneration_amount)

func heal(heal_amount : float) -> void:
	if canBeHealed():
		if getHealthPercent() > heal_treshold:
			setPolygon(start_poly)
			cur_area = start_area
			if hasRegeneration():
				regeneration_started = false
				regeneration_timer.stop()
		else:
			if total_frame_heal_amount == 0.0:
				call_deferred("restore")
			total_frame_heal_amount += heal_amount

func canBeHealed() -> bool:
	return getHealthPercent() < 1.0 and not isDead()

func getHealthPercent() -> float:
	if start_area == 0.0:
		return 0.0
	return cur_area / start_area

func hasRegeneration() -> bool:
	return regeneration_timer != null and regeneration_amount > 0.0

func isDead() -> bool:
	return cur_area <= 0.0

func restore() -> void:
	if total_frame_heal_amount > 0.0:
		var poly : PoolVector2Array
		var area : float = 0.0
		if polygon_restorer:
			var shape_entry : Dictionary = polygon_restorer.popLast()
			poly = shape_entry.shape
			area = shape_entry.area
		else:
			poly = PolygonLib.restorePolygon(_polygon2d.get_polygon(), start_poly, total_frame_heal_amount)
			area = PolygonLib.getPolygonArea(poly)
		
		if area / start_area > heal_treshold:
			cur_area = start_area
			setPolygon(start_poly)
		else:
			cur_area = area
			setPolygon(poly)
		
		if hasRegeneration():
			if getHealthPercent() < 1.0:
				if canRegenerate():
					var rand_time : float = _rng.randf_range(abs(regeneration_interval_range.x), abs(regeneration_interval_range.y))
					regeneration_timer.start(rand_time)
			else:
				regeneration_started = false
		
	total_frame_heal_amount = 0.0

func canRegenerate() -> bool:
	return (getHealthPercent() < regeneration_start_threshold or regeneration_started) and regeneration_timer.is_stopped()

func get_damage():
	if hasRegeneration():
		if canRegenerate():
			var rand_time : float = _rng.randf_range(abs(regeneration_interval_range.x), abs(regeneration_interval_range.y))
			regeneration_timer.start(rand_time)
			if not regeneration_started:
				regeneration_started = true
