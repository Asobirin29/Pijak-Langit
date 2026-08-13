## HealthItem.gd
## Item pemulihan nyawa di dunia Pijak Langit.
##
## Node: Area2D (Layer 4 / Mask 2)
## Saat player menyentuhnya:
##   1. Tambah +1 HP ke GameState.lives (cap MAX_LIVES = 3, via add_life())
##   2. Matikan collision segera
##   3. Jalankan tween animasi serupa LightShard (scale + fade)
##   4. queue_free()
##
## Variasi visual ditentukan via @export var item_name.
## Nama yang valid (string bebas, placeholder):
##   "Kelapa Cyber"    → warna hijau-toska
##   "Pepaya Hologram" → warna oranye-merah muda

extends Area2D

# ---------------------------------------------------------------------------
# EXPORT
# ---------------------------------------------------------------------------

## Nama item — menentukan warna placeholder visual.
## "Kelapa Cyber" atau "Pepaya Hologram"
@export_enum("Kelapa Cyber", "Pepaya Hologram") var item_name: String = "Kelapa Cyber"

# ---------------------------------------------------------------------------
# INTERNAL
# ---------------------------------------------------------------------------

## Peta nama → warna placeholder
const ITEM_COLORS: Dictionary = {
	"Kelapa Cyber":    Color(0.2, 0.9, 0.6, 1.0),   # hijau-toska neon
	"Pepaya Hologram": Color(1.0, 0.45, 0.2, 1.0),  # oranye panas
}

var _collected: bool = false

@onready var _visual: ColorRect           = $Visual
@onready var _label: Label                = $Label
@onready var _col_shape: CollisionShape2D = $CollisionShape2D
@onready var _collect_particles: GPUParticles2D = $CollectParticles

# ---------------------------------------------------------------------------
# LIFECYCLE
# ---------------------------------------------------------------------------

func _ready() -> void:
	# Terapkan warna berdasarkan nama item
	var col: Color = ITEM_COLORS.get(item_name, Color(0.9, 0.9, 0.9, 1.0))
	if _visual:
		_visual.color = col
		
	if _collect_particles:
		_collect_particles.modulate = col

	# Label opsional (tersembunyi saat runtime)
	if _label:
		_label.text = item_name
		_label.visible = false   # hanya tampil saat debug jika mau

	body_entered.connect(_on_body_entered)
	_start_idle_animation()


func _start_idle_animation() -> void:
	# Shard kesehatan: scale pulse (heartbeat)
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# ---------------------------------------------------------------------------
# SIGNALS
# ---------------------------------------------------------------------------

func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if not body.is_in_group("player"):
		return

	_collected = true

	# Matikan collision
	if _col_shape:
		_col_shape.set_deferred("disabled", true)

	# Tambah lives (GameState menanggani cap & emit lives_changed)
	GameState.add_life(1)
	AudioManager.play_sfx("sfx_collect")

	# Animasi pickup
	_play_collect_animation()


func _play_collect_animation() -> void:
	if _collect_particles:
		_collect_particles.restart()

	var tween := create_tween()
	tween.set_parallel(true)

	# Burst besar → menyusut ke nol
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.1)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "scale", Vector2(0.0, 0.0), 0.20)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Fade visual
	if _visual:
		tween.tween_property(_visual, "modulate:a", 0.0, 0.25)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.chain().tween_callback(queue_free)
