## FlyingEye.gd
## Musuh "Mata Terbang" untuk Pijak Langit.
##
## Node hierarki (lihat FlyingEye.tscn):
##   FlyingEye (CharacterBody2D)  <-- script ini, grup "enemy"
##     ├─ Visual (Node2D)
##     │    ├─ Body (ColorRect)          -- placeholder, ganti dengan Sprite2D
##     │    └─ GlowRect (ColorRect)      -- lapisan glow neon, animate via tween
##     ├─ DetectionZone (Area2D)         -- radius besar, trigger CHASE
##     │    └─ DetectionShape (CollisionShape2D)
##     ├─ Hurtbox (Area2D)              -- radius kecil, damage ke Player
##     │    └─ HurtboxShape (CollisionShape2D)
##     └─ ReturnTimer (Timer)           -- mundur sebelum kembali ke PATROL
##
## Collision layers yang disarankan:
##   FlyingEye body : layer "enemy"
##   DetectionZone  : layer "enemy_detection", mask "player"
##   Hurtbox        : layer "enemy"  -- agar Hurtbox.gd player mask "enemy" cocok
##
## Inspector exports:
##   patrol_points  -- Array[Vector2] dalam koordinat LOKAL node ini.
##                     Kosong => diam di tempat (idle patrol).
##   patrol_speed   -- kecepatan gerak saat PATROL (px/detik)
##   chase_speed    -- kecepatan gerak saat CHASE  (px/detik)
##   return_delay   -- detik tanpa kontak sebelum balik ke PATROL

extends CharacterBody2D

# ---------------------------------------------------------------------------
# CONSTANTS
# ---------------------------------------------------------------------------

const GLOW_ALPHA_MIN  : float = 0.25
const GLOW_ALPHA_MAX  : float = 0.85
const GLOW_PULSE_TIME : float = 0.65   # detik per setengah siklus pulse

# ---------------------------------------------------------------------------
# EXPORTED VARIABLES
# ---------------------------------------------------------------------------

## Titik-titik patrol dalam koordinat LOKAL node ini.
## Kosong = musuh idle diam di spawn position.
@export var patrol_points : Array[Vector2] = []

## Kecepatan saat PATROL (px/detik).
@export var patrol_speed  : float = 60.0

## Kecepatan saat CHASE (px/detik). Harus jauh lebih besar dari patrol_speed.
@export var chase_speed   : float = 240.0

## Durasi tanpa kontak (detik) sebelum musuh kembali ke PATROL.
@export var return_delay  : float = 2.0

## Warna neon utama body (atur dari Inspector sesuai tema level).
@export var neon_color    : Color = Color(0.0, 1.0, 0.85, 1.0)   # cyan

## Warna glow overlay.
@export var glow_color    : Color = Color(0.0, 1.0, 0.85, 0.55)

# ---------------------------------------------------------------------------
# STATE MACHINE
# ---------------------------------------------------------------------------

enum State { PATROL, CHASE }
var _state : State = State.PATROL

# ---------------------------------------------------------------------------
# RUNTIME VARS
# ---------------------------------------------------------------------------

var _player          : Node2D  = null   # referensi player saat CHASE
var _patrol_index    : int     = 0      # indeks titik patrol saat ini
var _origin          : Vector2          # posisi global saat _ready()
var _glow_tween      : Tween   = null
var _breath_tween    : Tween   = null

## Node references (diisi di _ready)
@onready var _visual       : Node2D   = $Visual
@onready var _body_sprite  : AnimatedSprite2D = $Visual/Body
@onready var _glow_rect    : ColorRect = $Visual/GlowRect
@onready var _detection    : Area2D   = $DetectionZone
@onready var _hurtbox      : Area2D   = $Hurtbox
@onready var _return_timer : Timer    = $ReturnTimer

# ---------------------------------------------------------------------------
# _READY
# ---------------------------------------------------------------------------

func _ready() -> void:
	_origin = global_position

	_body_sprite.modulate = neon_color
	_body_sprite.play("Fly")
	_glow_rect.color = glow_color

	# Timer kembali ke patrol
	_return_timer.wait_time = return_delay
	_return_timer.one_shot  = true
	_return_timer.timeout.connect(_on_return_timer_timeout)

	# DetectionZone signals
	_detection.body_entered.connect(_on_detection_body_entered)
	_detection.body_exited.connect(_on_detection_body_exited)

	# Mulai animasi glow pulse
	_start_glow_pulse()

	# Masuk grup enemy agar Hurtbox player (area_entered / body_entered) mendeteksi
	add_to_group("enemy")
	_hurtbox.add_to_group("enemy")

# ---------------------------------------------------------------------------
# _PHYSICS_PROCESS
# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	match _state:
		State.PATROL:
			_do_patrol(delta)
		State.CHASE:
			_do_chase(delta)

# ---------------------------------------------------------------------------
# PATROL LOGIC
# ---------------------------------------------------------------------------

func _do_patrol(_delta: float) -> void:
	if patrol_points.is_empty():
		# Idle: tidak bergerak
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Hitung target global dari titik lokal (relatif terhadap _origin)
	var target_global : Vector2 = _origin + patrol_points[_patrol_index]
	var direction     : Vector2 = target_global - global_position

	if direction.length() < 4.0:
		# Sampai di titik — pindah ke titik berikutnya (loop bolak-balik)
		_patrol_index = (_patrol_index + 1) % patrol_points.size()
	else:
		velocity = direction.normalized() * patrol_speed

	move_and_slide()

# ---------------------------------------------------------------------------
# CHASE LOGIC
# ---------------------------------------------------------------------------

func _do_chase(_delta: float) -> void:
	if not is_instance_valid(_player):
		_enter_patrol()
		return

	# Terbang bebas langsung ke posisi global player, tanpa gravitasi
	var direction : Vector2 = _player.global_position - global_position
	velocity = direction.normalized() * chase_speed if direction.length() > 1.0 \
			else Vector2.ZERO

	move_and_slide()

# ---------------------------------------------------------------------------
# STATE TRANSITIONS
# ---------------------------------------------------------------------------

func _enter_chase(player: Node2D) -> void:
	_state  = State.CHASE
	_player = player
	_return_timer.stop()
	_flash_visual(true)

func _enter_patrol() -> void:
	_state  = State.PATROL
	_player = null
	_return_timer.stop()
	_flash_visual(false)
	# Arahkan kembali ke titik patrol pertama
	_patrol_index = 0

# ---------------------------------------------------------------------------
# DETECTION CALLBACKS
# ---------------------------------------------------------------------------

func _on_detection_body_entered(body: Node2D) -> void:
	# Kenali Player lewat grup atau metode khas
	if body.is_in_group("player") or body.has_method("trigger_death"):
		_return_timer.stop()
		_enter_chase(body)

func _on_detection_body_exited(body: Node2D) -> void:
	if body == _player:
		# Player keluar zone — mulai hitung mundur
		_return_timer.start(return_delay)

# ---------------------------------------------------------------------------
# TIMER CALLBACK
# ---------------------------------------------------------------------------

func _on_return_timer_timeout() -> void:
	_enter_patrol()

# ---------------------------------------------------------------------------
# VISUAL: NEON GLOW PULSE (Tween)
# ---------------------------------------------------------------------------

func _start_glow_pulse() -> void:
	# Glow alpha pulse
	if _glow_tween:
		_glow_tween.kill()
	_glow_tween = create_tween()
	_glow_tween.set_loops()
	_glow_tween.set_ease(Tween.EASE_IN_OUT)
	_glow_tween.set_trans(Tween.TRANS_SINE)
	_glow_tween.tween_property(_glow_rect, "modulate:a", GLOW_ALPHA_MAX, GLOW_PULSE_TIME)
	_glow_tween.tween_property(_glow_rect, "modulate:a", GLOW_ALPHA_MIN, GLOW_PULSE_TIME)

	# Scale breathing pada body
	if _breath_tween:
		_breath_tween.kill()
	_breath_tween = create_tween()
	_breath_tween.set_loops()
	_breath_tween.set_ease(Tween.EASE_IN_OUT)
	_breath_tween.set_trans(Tween.TRANS_SINE)
	_breath_tween.tween_property(_body_sprite, "scale", Vector2(1.12, 1.12), GLOW_PULSE_TIME)
	_breath_tween.tween_property(_body_sprite, "scale", Vector2(0.92, 0.92), GLOW_PULSE_TIME)

## Flash kilat saat transisi state — modulate seluruh Visual node sesaat.
func _flash_visual(entering_chase: bool) -> void:
	var fc := Color(1.0, 0.2, 0.9, 1.0) if entering_chase \
			else Color(0.2, 1.0, 0.85, 1.0)
	var ft := create_tween()
	ft.set_ease(Tween.EASE_OUT)
	ft.set_trans(Tween.TRANS_QUINT)
	ft.tween_property(_visual, "modulate", fc,          0.08)
	ft.tween_property(_visual, "modulate", Color.WHITE, 0.25)
