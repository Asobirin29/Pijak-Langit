## LightShard.gd
## Collectible shard cahaya di dunia Pijak Langit.
##
## Node: Area2D (Layer 4 / Mask 2 → deteksi player CharacterBody2D)
## Saat player menyentuhnya:
##   1. Tambah +1 ke GameState.score (via add_score() → emit score_changed)
##   2. Matikan collision segera (jangan double-pickup)
##   3. Jalankan tween: scale up → scale 0 sambil fade out
##   4. queue_free()

extends Area2D

# ---------------------------------------------------------------------------
# EXPORT
# ---------------------------------------------------------------------------

## Warna cahaya shard. Bisa di-override per-instance dari Inspector.
@export var shard_color: Color = Color(0.6, 1.0, 1.0, 1.0)

## Nilai skor yang ditambahkan saat diambil.
@export var score_value: int = 1

# ---------------------------------------------------------------------------
# PRIVATE
# ---------------------------------------------------------------------------

var _collected: bool = false

# Node refs (resolved di _ready)
@onready var _visual: ColorRect       = $Visual
@onready var _col_shape: CollisionShape2D = $CollisionShape2D

# ---------------------------------------------------------------------------
# LIFECYCLE
# ---------------------------------------------------------------------------

func _ready() -> void:
	# Terapkan warna ke visual placeholder
	if _visual:
		_visual.color = shard_color

	# Hubungkan sinyal body_entered (player CharacterBody2D masuk area)
	body_entered.connect(_on_body_entered)

	# Animasi idle: shard berputar perlahan via tween looping
	_start_idle_animation()


func _start_idle_animation() -> void:
	# Floating bob: gerak naik-turun halus
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - 4.0, 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", position.y, 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# ---------------------------------------------------------------------------
# SIGNALS
# ---------------------------------------------------------------------------

func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	# Pastikan yang masuk adalah player
	if not body.is_in_group("player"):
		return

	_collected = true

	# 1. Matikan collision agar tidak trigger lagi
	if _col_shape:
		_col_shape.set_deferred("disabled", true)

	# 2. Tambah skor ke GameState (sudah emit signal score_changed di sana)
	GameState.add_score(score_value)
	AudioManager.play_sfx("sfx_collect")

	# 3. Jalankan animasi pickup: scale burst → shrink + fade
	_play_collect_animation()


func _play_collect_animation() -> void:
	# Trigger particles
	var collect_particles = $CollectParticles
	if collect_particles:
		collect_particles.restart()

	# Hentikan tween idle dulu
	var tweens := get_tree().get_nodes_in_group("__tweens__")
	# (kita buat tween baru yang override state)

	var tween := create_tween()
	tween.set_parallel(true)

	# Scale burst ke 1.6, lalu kecil ke 0
	tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.08)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "scale", Vector2(0.0, 0.0), 0.18)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Fade out visual
	if _visual:
		tween.tween_property(_visual, "modulate:a", 0.0, 0.22)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Setelah animasi selesai, bebaskan node
	tween.chain().tween_callback(queue_free)
