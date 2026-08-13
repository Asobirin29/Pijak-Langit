## FallingLava.gd
## Mekanik hazard baru untuk Bioma 2: Puncak Vulkanik
## Lava jatuh secara dinamis mengikuti arah gravitasi player saat trigger diaktifkan.

extends Area2D

@export var fall_gravity: float = 800.0
@export var trigger_distance_y: float = 400.0
@export var trigger_distance_x: float = 64.0
@export var reset_time: float = 2.0

var _is_falling: bool = false
var _fall_direction: int = 1
var _velocity: Vector2 = Vector2.ZERO
var _start_position: Vector2

var _player: Node2D

func _ready() -> void:
	_start_position = global_position
	add_to_group("hazard")
	
	# Hubungkan sinyal untuk mendeteksi collision dengan environment (lantai/dinding)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if not _is_falling:
		_check_trigger()
	else:
		# Lakukan jatuh
		_velocity.y += fall_gravity * _fall_direction * delta
		position += _velocity * delta
		
		# Jika lava jatuh terlalu jauh dari layar, reset
		if abs(global_position.y - _start_position.y) > 1000:
			_reset_lava()

func _check_trigger() -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
		
	if _player:
		var diff = _player.global_position - global_position
		
		# Deteksi apakah player berada dalam rentang X yang ditentukan
		if abs(diff.x) < trigger_distance_x:
			# Dapatkan arah gravitasi player
			var p_grav = 1
			if "gravity_direction" in _player:
				p_grav = _player.gravity_direction
				
			# Cek apakah player berada di "bawah" lava secara relatif terhadap gravitasi
			# Jika gravitasi normal (1), player harus berada di bawah lava (y > 0)
			# Jika gravitasi terbalik (-1), player harus berada di atas lava (y < 0)
			if (p_grav == 1 and diff.y > 0 and diff.y < trigger_distance_y) or \
			   (p_grav == -1 and diff.y < 0 and diff.y > -trigger_distance_y):
				
				_trigger_fall(p_grav)

func _trigger_fall(grav_dir: int) -> void:
	_is_falling = true
	_fall_direction = grav_dir
	_velocity = Vector2.ZERO

func _on_body_entered(body: Node2D) -> void:
	if _is_falling:
		# Jika menabrak lantai atau dinding, hancur dan reset
		_reset_lava()

func _reset_lava() -> void:
	_is_falling = false
	_velocity = Vector2.ZERO
	position = _start_position
	# Sembunyikan sebentar atau nonaktifkan?
	visible = false
	set_deferred("monitoring", false)
	
	await get_tree().create_timer(reset_time).timeout
	
	visible = true
	set_deferred("monitoring", true)
