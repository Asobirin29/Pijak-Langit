## Spike.gd
## Rintangan statis duri yang memicu instant-death saat Player menyentuh
## area ujung tajamnya.
##
## Setup Scene:
##   Spike (StaticBody2D)  <-- script ini
##     Body (CollisionShape2D)   <-- body solid (full box) untuk fisika
##     HurtArea (Area2D)         <-- area hazard di ujung tajam duri
##       HurtShape (CollisionShape2D)
##     Visual (Node2D)
##       SpriteDraw (Node2D)     <-- gambar duri via _draw()
##
## Cara pakai di Editor:
##   - Putar seluruh node Spike 180 derajat di Inspector (rotation = 3.14159)
##     untuk menempatkan duri di langit-langit.
##   - Scene bisa diinstansiasi berkali-kali dalam TileMap / Level scene.
##
## Collision layers yang disarankan:
##   - Spike (StaticBody2D) : layer "world"
##   - HurtArea             : layer "hazard", mask "player_hurtbox"
##
## Grup:
##   - Spike (StaticBody2D) : "hazard"  -> agar _on_body_entered di Hurtbox.gd menangkapnya
##   - HurtArea             : "hazard"  -> agar _on_area_entered di Hurtbox.gd menangkapnya

extends StaticBody2D

## Ukuran duri dalam piksel.
@export var spike_width: float  = 16.0
@export var spike_height: float = 20.0

## Warna duri (placeholder visual).
@export var spike_color: Color = Color(0.85, 0.15, 0.15)

@onready var _hurt_area: Area2D  = $HurtArea
@onready var _sprite_draw: Node2D = $Visual/SpriteDraw


func _ready() -> void:
	# StaticBody2D sendiri masuk grup "hazard"
	# sehingga Hurtbox.gd (_on_body_entered) mendeteksinya.
	add_to_group("hazard")

	# HurtArea masuk grup "hazard" untuk path _on_area_entered.
	_hurt_area.add_to_group("hazard")

	# Paksa redraw agar parameter @export teraplikasi ke visual.
	_sprite_draw.queue_redraw()
