## Hurtbox.gd
## Komponen Area2D pada Player yang mendeteksi kontak dengan
## node dari grup "enemy" atau "hazard" dan memicu instant-death.
##
## Setup Scene (child dari Player):
##   Hurtbox (Area2D) <-- script ini
##     CollisionShape2D  <-- sesuaikan ukuran dengan sprite Player
##
## Collision layer / mask:
##   - Hurtbox: layer "player_hurtbox", mask "enemy" + "hazard"

extends Area2D

## Referensi ke Player parent. Diisi otomatis di _ready().
var _player: Node2D


func _ready() -> void:
	_player = get_parent()
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


# Deteksi Area2D enemy/hazard (misalnya hitbox musuh).
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy") or area.is_in_group("hazard"):
		_request_death()


# Deteksi StaticBody2D / CharacterBody2D enemy/hazard (opsional).
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") or body.is_in_group("hazard"):
		_request_death()


func _request_death() -> void:
	if _player and _player.has_method("trigger_death"):
		_player.trigger_death()
