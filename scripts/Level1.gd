## Level1.gd
## Script untuk Level 1 — "Hutan Akar Gantung".
## Menghubungkan sinyal LevelGoal ke transisi scene berikutnya (placeholder).

extends Node2D


func _ready() -> void:
	# Sambungkan sinyal level_completed dari LevelGoal
	var goal := $LevelGoal
	if goal:
		goal.level_completed.connect(_on_level_completed)

	# Pastikan GameState di-reset agar lives & checkpoint bersih di awal
	# (Hanya di-reset jika dipanggil sebagai level baru, bukan respawn)
	# GameState.reset()  # uncomment jika mau reset penuh saat masuk level


func _on_level_completed() -> void:
	print("[Level1] Level selesai! Menampilkan layar Level Complete...")
	
	# Slow down time briefly before showing the screen
	Engine.time_scale = 0.3
	await get_tree().create_timer(1.0, true, false, true).timeout
	Engine.time_scale = 1.0
	
	var level_complete_scene = load("res://scenes/ui/LevelCompleteScreen.tscn")
	var level_complete_instance = level_complete_scene.instantiate()
	get_tree().root.add_child(level_complete_instance)
