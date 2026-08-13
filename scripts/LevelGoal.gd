## LevelGoal.gd
## Area2D portal/goal di akhir level.
## Pancarkan sinyal "level_completed" saat Player memasuki area ini.
##
## Setup Scene:
##   LevelGoal (Area2D)  <-- script ini
##     CollisionShape2D
##     Visual (Node2D / AnimatedSprite2D / ColorRect placeholder)
##
## Player harus berada dalam grup "player".

extends Area2D

## Sinyal utama — dengarkan dari Level atau GameManager untuk transisi level.
signal level_completed
## Sinyal tambahan untuk menandakan tamat.
signal game_completed

@export var is_final_level: bool = false

## Cegah trigger ganda.
var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if not body.is_in_group("player"):
		return

	_triggered = true
	print("[LevelGoal] Level selesai! Player: %s" % body.name)
	
	if is_final_level:
		game_completed.emit()
	else:
		level_completed.emit()


## Reset jika level di-reload.
func reset_goal() -> void:
	_triggered = false
