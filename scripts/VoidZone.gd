## VoidZone.gd
## Area2D yang memicu instant-death saat Player memasukinya.
## Letakkan di bawah/luar batas level.
##
## Setup Scene:
##   VoidZone (Area2D) <-- script ini
##     CollisionShape2D  <-- bisa WorldBoundaryShape2D atau RectangleShape2D lebar
##
## Player harus:
##   - Memiliki method  trigger_death()
##   - Berada dalam grup "player"

extends Area2D

func _ready() -> void:
	# Hanya deteksi objek di layer physics; pastikan collision mask mencakup layer Player.
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("trigger_death"):
			body.trigger_death()
