## MovingPlatform.gd
## Platform bergerak bolak-balik menggunakan AnimatableBody2D.
## Karena menggunakan AnimatableBody2D, properti fisika (seperti velositas) 
## akan otomatis diturunkan ke Player yang berada di atasnya.

extends AnimatableBody2D

@export var waypoints: Array[Vector2] = [Vector2.ZERO, Vector2(100, 0)]
@export var move_duration: float = 2.0
@export var pause_time: float = 0.5
@export var ping_pong: bool = true

var _current_index: int = 0
var _moving_forward: bool = true
var _base_position: Vector2

func _ready() -> void:
	_base_position = position
	if waypoints.is_empty():
		return
	# Mulai pergerakan ke waypoint berikutnya
	_move_to_next()

func _move_to_next() -> void:
	if waypoints.size() <= 1:
		return
		
	if _moving_forward:
		_current_index += 1
		if _current_index >= waypoints.size():
			if ping_pong:
				_moving_forward = false
				_current_index = waypoints.size() - 2
			else:
				_current_index = 0
	else:
		_current_index -= 1
		if _current_index < 0:
			if ping_pong:
				_moving_forward = true
				_current_index = 1
			else:
				_current_index = waypoints.size() - 1
				
	# Pastikan indeks tidak out of bounds (jika array sangat kecil)
	_current_index = clampi(_current_index, 0, waypoints.size() - 1)
	
	var target_pos = _base_position + waypoints[_current_index]
	var tween = create_tween()
	# Gunakan animasi SINE untuk pergerakan halus di ujung
	tween.tween_property(self, "position", target_pos, move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_on_tween_finished)

func _on_tween_finished() -> void:
	if pause_time > 0.0:
		await get_tree().create_timer(pause_time).timeout
	_move_to_next()
