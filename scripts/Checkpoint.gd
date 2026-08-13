## Checkpoint.gd
## Area2D yang menyimpan posisi & gravity_direction saat Player memasukinya.
##
## Setup Scene:
##   Checkpoint (Area2D) <-- script ini
##     CollisionShape2D
##     Sprite2D / AnimatedSprite2D  (opsional, visual flag/banner)
##
## Player harus:
##   - Memiliki property  gravity_direction: int
##   - Berada dalam grup  "player"

extends Area2D

## Sinyal dipancarkan saat checkpoint diaktifkan (berguna untuk visual/SFX).
signal activated

## Cegah aktivasi berulang saat player berdiri di atasnya.
var _already_activated: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _already_activated:
		return
	if not body.is_in_group("player"):
		return

	# Ambil gravity_direction dari Player; default 1 jika tidak ditemukan.
	var grav_dir: int = 1
	if "gravity_direction" in body:
		grav_dir = body.gravity_direction

	# Simpan ke GameState singleton.
	GameState.save_checkpoint(global_position, grav_dir)

	_already_activated = true
	activated.emit()

	# Opsional: visual feedback (misalnya animasi flag).
	# $AnimatedSprite2D.play("active")
	print("[Checkpoint] Aktif di: %s (gravity=%d)" % [global_position, grav_dir])


## Reset checkpoint (dipanggil jika level di-reload).
func reset_checkpoint() -> void:
	_already_activated = false
