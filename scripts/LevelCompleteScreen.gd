extends CanvasLayer

@onready var bg: ColorRect = $Control/ColorRect
@onready var score_label: Label = $Control/VBoxContainer/ScoreLabel
@onready var next_button: Button = $Control/VBoxContainer/NextButton

func _ready() -> void:
	get_tree().paused = true
	
	bg.modulate.a = 0.0
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(bg, "modulate:a", 1.0, 0.5)
	
	if score_label:
		score_label.text = "Final Score: " + str(GameState.score)
	
	if next_button:
		next_button.pressed.connect(_on_next_pressed)

func _on_next_pressed() -> void:
	if next_button:
		next_button.disabled = true
	
	print("[LevelCompleteScreen] Next button pressed. Resetting and transitioning...")
	GameState.reset()
	
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property($Control, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	get_tree().paused = false
	
	var current_scene_name = get_tree().current_scene.name
	if current_scene_name == "Level1":
		get_tree().change_scene_to_file("res://scenes/levels/Level2.tscn")
	else:
		get_tree().reload_current_scene()
