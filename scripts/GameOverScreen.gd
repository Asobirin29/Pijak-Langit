extends CanvasLayer

@onready var bg: ColorRect = $Control/ColorRect
@onready var restart_button: Button = $Control/VBoxContainer/RestartButton

func _ready() -> void:
	# Pause tree if we want the game to freeze behind the screen. But if player blocks input, we might not need to pause.
	# Let's pause it just to be safe and clean.
	get_tree().paused = true
	
	bg.modulate.a = 0.0
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(bg, "modulate:a", 1.0, 0.5)
	
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quick_restart"):
		_on_restart_pressed()

func _on_restart_pressed() -> void:
	set_process_input(false)
	if restart_button:
		restart_button.disabled = true
		
	GameState.reset()
	
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property($Control, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	get_tree().paused = false
	get_tree().reload_current_scene()
