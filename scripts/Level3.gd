## Level3.gd
## Script untuk Level 3 — "Reruntuhan Joglo Udara".
## Menghubungkan sinyal LevelGoal ke transisi game over/game completed.

extends Node2D

func _ready() -> void:
	# Sambungkan sinyal game_completed dari LevelGoal
	var goal := $LevelGoal
	if goal:
		goal.game_completed.connect(_on_game_completed)

func _on_game_completed() -> void:
	print("[Level3] Game Tamat! Menampilkan layar penutup...")
	
	# Slow down time briefly before showing the screen
	Engine.time_scale = 0.3
	await get_tree().create_timer(1.0, true, false, true).timeout
	Engine.time_scale = 1.0
	
	# Pindah ke layar ending atau kembali ke menu utama. 
	# Karena belum ada layarnya, kita print dan reset ke main menu.
	print("VICTORY! YOU HAVE COMPLETED THE GAME!")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
