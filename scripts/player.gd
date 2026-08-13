## player.gd
## Script utama Player untuk Pijak Langit.
## Fase 4: Death & Checkpoint -- VoidZone, Hurtbox, respawn dengan fade overlay.

class_name Player
extends CharacterBody2D

# ---------------------------------------------------------------------------
# SIGNALS
# ---------------------------------------------------------------------------

## Dipancarkan setiap kali gravity_direction berhasil dibalik.
## gravity_dir: nilai baru gravity_direction (1 atau -1).
signal gravity_flipped(gravity_dir: int)

## Dipancarkan sesaat sebelum proses respawn dimulai.
signal died


# ---------------------------------------------------------------------------
# EXPORTED VARIABLES -- bisa di-tweak langsung dari Inspector Godot
# ---------------------------------------------------------------------------

## Posisi spawn awal Player di level ini.
## Di-set otomatis dari global_position saat _ready();
## bisa di-override manual dari Inspector jika spawn point berbeda dari posisi node.
@export var spawn_position: Vector2 = Vector2.ZERO

## Kecepatan maksimum horizontal (piksel per detik).
@export var speed: float = 200.0

## Seberapa cepat player MENCAPAI speed penuh saat tombol ditekan.
@export var acceleration: float = 1200.0

## Seberapa cepat player MELAMBAT saat tombol dilepas.
@export var friction: float = 800.0

## Kekuatan lompatan (piksel per detik).
@export var jump_velocity: float = 420.0

## Durasi coyote time dalam detik.
@export var coyote_time: float = 0.10

## Cooldown antar gravity flip (detik). Mencegah spam yang merusak balancing.
@export var flip_cooldown: float = 0.30

## Durasi tween rotasi kamera saat flip (detik).
@export var camera_flip_duration: float = 0.25

## Intensitas screen shake saat flip (piksel maks perpindahan kamera).
@export var shake_intensity: float = 3.0

## Durasi screen shake (detik).
@export var shake_duration: float = 0.20

## Durasi flash effect saat flip (detik).
@export var flash_duration: float = 0.15

## Warna flash saat flip (alpha menentukan intensitas).
@export var flash_color: Color = Color(1.0, 1.0, 1.0, 0.35)


# ---------------------------------------------------------------------------
# GRAVITY
# ---------------------------------------------------------------------------

## Konstanta gravitasi per detik^2. Mengambil nilai dari ProjectSettings.
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

## Arah gravitasi aktif:
##   1  = normal   -- gravitasi menarik ke bawah
##  -1  = terbalik -- gravitasi menarik ke atas
var gravity_direction: int = 1


# ---------------------------------------------------------------------------
# FLIP STATE
# ---------------------------------------------------------------------------

## Sisa waktu cooldown flip (detik). Flip diblokir selama > 0.
var _flip_cooldown_timer: float = 0.0


# ---------------------------------------------------------------------------
# STATE MACHINE
# ---------------------------------------------------------------------------

enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
}

var current_state: State = State.IDLE


# ---------------------------------------------------------------------------
# DEATH STATE
# ---------------------------------------------------------------------------

## True selama proses death/respawn berlangsung.
## Memblokir _physics_process dan input baru.
var _is_dead: bool = false

## Referensi ke RespawnOverlay (CanvasLayer) yang dibuat saat pertama mati.
var _respawn_overlay: Node


# ---------------------------------------------------------------------------
# COYOTE TIME
# ---------------------------------------------------------------------------

var _coyote_timer: float = 0.0


# ---------------------------------------------------------------------------
# ONREADY -- referensi ke child nodes
# ---------------------------------------------------------------------------

## AnimatedSprite2D sebagai visual utama.
@onready var sprite: AnimatedSprite2D = $Sprite

## Camera2D yang mengikuti player dengan smooth flip.
@onready var camera: Camera2D = $Camera2D

## CanvasLayer untuk overlay flash effect.
@onready var flash_layer: CanvasLayer = $FlashLayer

## ColorRect overlay untuk flash effect (child dari FlashLayer).
@onready var flash_rect: ColorRect = $FlashLayer/FlashRect

@onready var flip_particles: GPUParticles2D = $FlipParticles
@onready var death_particles: GPUParticles2D = $DeathParticles


# ---------------------------------------------------------------------------
# INTERNAL TWEEN HANDLES
# ---------------------------------------------------------------------------

var _camera_tween: Tween
var _shake_tween: Tween
var _flash_tween: Tween


# ---------------------------------------------------------------------------
# READY
# ---------------------------------------------------------------------------

func _ready() -> void:
	if not sprite:
		push_warning("Player: Node 'Sprite' (AnimatedSprite2D) tidak ditemukan!")
	if not camera:
		push_warning("Player: Node 'Camera2D' tidak ditemukan!")
	if not flash_layer:
		push_warning("Player: Node 'FlashLayer' (CanvasLayer) tidak ditemukan!")
	if not flash_rect:
		push_warning("Player: Node 'FlashRect' (ColorRect) tidak ditemukan!")

	# Pastikan flash rect transparan di awal.
	if flash_rect:
		flash_rect.color = Color(flash_color.r, flash_color.g, flash_color.b, 0.0)

	# Set up_direction awal sesuai gravity_direction default.
	_sync_up_direction()

	# Daftarkan ke grup agar VoidZone & Hurtbox bisa mendeteksi.
	add_to_group("player")

	# Simpan posisi spawn ke GameState sebagai fallback respawn.
	if spawn_position == Vector2.ZERO:
		spawn_position = global_position
	GameState.level_spawn_position = spawn_position


# ---------------------------------------------------------------------------
# PHYSICS PROCESS
# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	# Blokir semua proses fisik saat player sedang mati / respawn.
	if _is_dead:
		return

	# 1. Hitung cooldown timer.
	_flip_cooldown_timer = max(_flip_cooldown_timer - delta, 0.0)

	# 2. Proses input gravity flip (Spacebar).
	_process_flip_input()

	# 3. Deteksi grounded.
	var grounded: bool = _is_grounded()

	# 4. Kelola coyote timer.
	_update_coyote_timer(grounded, delta)

	# 5. Terapkan gravitasi.
	_apply_gravity(delta)

	# 6. Input horizontal.
	var input_dir: float = Input.get_axis("ui_left", "ui_right")

	# 7. Akselerasi / friction.
	_apply_horizontal_movement(input_dir, delta)
	
	if input_dir != 0.0 and sprite:
		sprite.flip_h = input_dir < 0.0

	# 8. Input jump (W / Panah Atas).
	_process_jump_input()

	# 9. Update state machine.
	_update_state(input_dir, grounded)

	# 10. Gerakkan CharacterBody2D.
	move_and_slide()


# ---------------------------------------------------------------------------
# GRAVITY FLIP -- inti mekanik
# ---------------------------------------------------------------------------

## Membaca input gravity_flip dan memulai proses flip jika cooldown sudah habis.
func _process_flip_input() -> void:
	if Input.is_action_just_pressed("gravity_flip"):
		if _flip_cooldown_timer <= 0.0:
			_execute_gravity_flip()


## Menjalankan semua efek flip: membalik gravity_direction, sprite, kamera, shake, flash.
func _execute_gravity_flip() -> void:
	# Balik nilai gravity_direction.
	gravity_direction = -gravity_direction

	# Set cooldown.
	_flip_cooldown_timer = flip_cooldown

	# Sinkronkan up_direction CharacterBody2D agar is_on_floor() bekerja benar.
	_sync_up_direction()

	# Balik scale.y sprite agar orientasi visual karakter sesuai gravitasi baru.
	_flip_sprite_vertical()

	# Tween rotasi kamera secara smooth.
	_tween_camera_rotation()

	# Screen shake kecil.
	_trigger_screen_shake()

	# Flash singkat.
	_trigger_flash()
	
	# Particles
	if flip_particles:
		flip_particles.restart()

	# Emit sinyal agar sistem lain (HUD, SFX) bisa bereaksi.
	gravity_flipped.emit(gravity_direction)

	print("Gravity flip! Arah baru: %d" % gravity_direction)


## Sinkronkan up_direction CharacterBody2D dengan gravity_direction saat ini.
## Ini membuat is_on_floor() bekerja secara semantis benar di kedua arah gravitasi:
##   gravity_direction =  1 (up=UP)   -- is_on_floor() true saat di lantai bawah
##   gravity_direction = -1 (up=DOWN) -- is_on_floor() true saat di langit-langit
func _sync_up_direction() -> void:
	if gravity_direction == 1:
		up_direction = Vector2.UP
	else:
		up_direction = Vector2.DOWN


## Flip flip_v sprite (visual) agar karakter terlihat terbalik saat gravitasi terbalik.
func _flip_sprite_vertical() -> void:
	if sprite:
		sprite.flip_v = (gravity_direction == -1)


# ---------------------------------------------------------------------------
# KAMERA -- smooth rotation tween saat flip
# ---------------------------------------------------------------------------

## Tween rotasi kamera dari rotasi saat ini ke target (0 atau PI radian).
## Memberikan transisi visual yang smooth, tidak snap langsung.
func _tween_camera_rotation() -> void:
	if not camera:
		return

	# Batalkan tween sebelumnya jika masih berjalan.
	if _camera_tween and _camera_tween.is_valid():
		_camera_tween.kill()

	# Target rotasi: 0.0 = normal, PI = terbalik (180 derajat).
	var target_rotation: float = 0.0 if gravity_direction == 1 else PI

	_camera_tween = create_tween()
	_camera_tween.set_ease(Tween.EASE_IN_OUT)
	_camera_tween.set_trans(Tween.TRANS_CUBIC)
	_camera_tween.tween_property(
		camera,
		"rotation",
		target_rotation,
		camera_flip_duration
	)


# ---------------------------------------------------------------------------
# EFEK TRANSISI -- screen shake & flash
# ---------------------------------------------------------------------------

## Screen shake kecil: mengoffset kamera beberapa piksel bolak-balik.
func _trigger_screen_shake() -> void:
	if not camera:
		return

	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()

	var origin: Vector2 = Vector2.ZERO

	_shake_tween = create_tween()
	_shake_tween.set_loops(4)
	_shake_tween.tween_property(
		camera, "offset",
		Vector2(randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)),
		shake_duration / 8.0
	)
	_shake_tween.tween_property(
		camera, "offset",
		origin,
		shake_duration / 8.0
	)
	# Pastikan offset kembali ke nol setelah semua loop selesai.
	_shake_tween.set_loops(1)
	_shake_tween.tween_property(camera, "offset", origin, 0.0)


## Flash singkat via ColorRect di CanvasLayer: fade in lalu fade out.
## Memberikan feedback visual bahwa flip terjadi (placeholder sebelum VFX/SFX asli).
func _trigger_flash() -> void:
	if not flash_rect:
		return

	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()

	flash_rect.color = Color(flash_color.r, flash_color.g, flash_color.b, 0.0)

	_flash_tween = create_tween()
	# Fade in (30% dari total durasi).
	_flash_tween.tween_property(
		flash_rect, "color",
		flash_color,
		flash_duration * 0.3
	)
	# Fade out (70% dari total durasi).
	_flash_tween.tween_property(
		flash_rect, "color",
		Color(flash_color.r, flash_color.g, flash_color.b, 0.0),
		flash_duration * 0.7
	)


# ---------------------------------------------------------------------------
# PRIVATE HELPERS
# ---------------------------------------------------------------------------

## Mengembalikan true jika player menempel pada permukaan "bawah" sesuai gravitasi.
## Dengan up_direction yang sudah disinkronkan via _sync_up_direction(),
## is_on_floor() sudah bekerja benar di kedua arah gravitasi secara otomatis.
func _is_grounded() -> bool:
	return is_on_floor()


## Mengelola countdown coyote timer.
func _update_coyote_timer(grounded: bool, delta: float) -> void:
	if grounded:
		_coyote_timer = coyote_time
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)


## Menerapkan gravitasi ke velocity.y setiap physics frame.
func _apply_gravity(delta: float) -> void:
	if not _is_grounded():
		velocity.y += _gravity * gravity_direction * delta


## Menghitung velocity.x dengan smooth acceleration / friction.
func _apply_horizontal_movement(input_dir: float, delta: float) -> void:
	if input_dir != 0.0:
		velocity.x = move_toward(velocity.x, input_dir * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


## Input lompat: W atau Panah Atas.
## Impulse velocity.y berlawanan arah gravitasi.
func _process_jump_input() -> void:
	if Input.is_action_just_pressed("ui_up"):
		if _coyote_timer > 0.0:
			velocity.y = -jump_velocity * gravity_direction
			_coyote_timer = 0.0


## Memperbarui current_state berdasarkan kondisi fisik dan input.
func _update_state(input_dir: float, grounded: bool) -> void:
	var new_state: State

	if grounded:
		if input_dir == 0.0 and is_zero_approx(velocity.x):
			new_state = State.IDLE
		else:
			new_state = State.RUN
	else:
		var rising: bool = (velocity.y * gravity_direction) < 0.0
		new_state = State.JUMP if rising else State.FALL

	if new_state != current_state:
		_on_state_changed(current_state, new_state)
		current_state = new_state


## Dipanggil saat state bertransisi.
func _on_state_changed(from: State, to: State) -> void:
	print("Player state: %s -> %s" % [State.keys()[from], State.keys()[to]])

	match to:
		State.IDLE:
			if sprite: sprite.play("Idle")
		State.RUN:
			if sprite: sprite.play("Run")
		State.JUMP:
			if sprite: sprite.play("Jump")
		State.FALL:
			if sprite: sprite.play("Fall")


# ---------------------------------------------------------------------------
# DEATH & RESPAWN
# ---------------------------------------------------------------------------

## Entry-point kematian. Dipanggil oleh VoidZone, Hurtbox, atau sistem lain.
## Idempoten: jika sudah dead, panggilan berikutnya diabaikan.
func trigger_death() -> void:
	if _is_dead:
		return

	_is_dead = true
	velocity = Vector2.ZERO
	
	if death_particles:
		death_particles.restart()
		
	# Hide sprite when dead
	if sprite:
		sprite.hide()

	var remaining: int = GameState.consume_life()
	print("[Player] Mati! Sisa lives: %d" % remaining)
	died.emit()

	if remaining <= 0:
		var game_over_scene = load("res://scenes/ui/GameOverScreen.tscn")
		var game_over_instance = game_over_scene.instantiate()
		get_tree().root.add_child(game_over_instance)
		# Jangan set _is_dead = false agar player tetap terblokir dari update physics
		return

	# Buat overlay fade jika belum ada.
	if not _respawn_overlay:
		var overlay_script := load("res://scripts/RespawnOverlay.gd")
		_respawn_overlay = overlay_script.new()
		get_tree().root.add_child(_respawn_overlay)

	# Jalankan fade dan respawn secara async.
	await _respawn_overlay.do_respawn_fade(_do_respawn)

	_is_dead = false


## Dipanggil di tengah fade (layar hitam) -- aman untuk teleport.
func _do_respawn() -> void:
	# Ambil data respawn dari GameState.
	var target_pos: Vector2 = GameState.get_respawn_position()
	var target_grav: int   = GameState.get_respawn_gravity()

	# Reset posisi.
	global_position = target_pos

	# Reset velocity.
	velocity = Vector2.ZERO

	# Reset gravity_direction.
	gravity_direction = target_grav
	_sync_up_direction()

	# Reset sprite agar orientasi sesuai gravity baru.
	if sprite:
		sprite.flip_v = (gravity_direction == -1)
		sprite.show()

	# Sinkronkan rotasi kamera langsung (tanpa tween) agar tidak terlihat aneh.
	if camera:
		if _camera_tween and _camera_tween.is_valid():
			_camera_tween.kill()
		camera.rotation = 0.0 if gravity_direction == 1 else PI

	# Reset flip cooldown.
	_flip_cooldown_timer = 0.0

	print("[Player] Respawn di: %s (gravity=%d)" % [target_pos, target_grav])
