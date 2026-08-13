extends CanvasLayer

@onready var score_label: Label = $MarginContainer/HBoxContainer/ScoreLabel
@onready var lives_container: HBoxContainer = $MarginContainer/HBoxContainer/LivesContainer
@onready var gravity_icon: Control = $MarginContainer/HBoxContainer/GravityArrow

func _ready() -> void:
	# Connect to GameState signals
	GameState.score_changed.connect(_on_score_changed)
	GameState.lives_changed.connect(_on_lives_changed)
	
	# Attempt to connect to Player signal
	# Since HUD might load before or after Player, we use call_deferred
	# or find it via group. If not found initially, we can wait or find it.
	var player = get_tree().get_first_node_in_group("player")
	if player:
		_setup_player(player)
	else:
		# If player is not in tree yet, wait for node added
		get_tree().node_added.connect(_on_node_added)
	
	# Initialize HUD based on current state
	_on_score_changed(GameState.score)
	_on_lives_changed(GameState.lives)

func _setup_player(player: Node) -> void:
	if not player.is_connected("gravity_flipped", _on_gravity_flipped):
		player.gravity_flipped.connect(_on_gravity_flipped)
		_update_gravity_icon(player.gravity_direction)

func _on_node_added(node: Node) -> void:
	if node.is_in_group("player"):
		_setup_player(node)
		# Disconnect to save performance since player is found
		if get_tree().node_added.is_connected(_on_node_added):
			get_tree().node_added.disconnect(_on_node_added)

func _on_score_changed(new_score: int) -> void:
	score_label.text = "SCORE: %04d" % new_score
	
	# Simple scale bounce animation
	score_label.pivot_offset = score_label.size / 2.0
	var tween = create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.1)

func _on_lives_changed(new_lives: int) -> void:
	var icons = lives_container.get_children()
	for i in range(icons.size()):
		var icon = icons[i] as ColorRect
		var is_active = i < new_lives
		
		# Base icon settings
		icon.pivot_offset = icon.custom_minimum_size / 2.0
		
		var tween = create_tween()
		
		if is_active and icon.modulate.a < 1.0:
			# Life gained / Restored
			icon.modulate.a = 1.0
			tween.tween_property(icon, "scale", Vector2(1.5, 1.5), 0.15)
			tween.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.15)
		elif not is_active and icon.modulate.a > 0.0:
			# Life lost
			tween.tween_property(icon, "scale", Vector2(1.5, 1.5), 0.1)
			tween.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.1)
			tween.tween_property(icon, "modulate:a", 0.3, 0.15) # Dimmed when lost

func _on_gravity_flipped(gravity_dir: int) -> void:
	_update_gravity_icon(gravity_dir)
	
	# Pop animation for the gravity icon
	gravity_icon.pivot_offset = gravity_icon.custom_minimum_size / 2.0
	var tween = create_tween()
	tween.tween_property(gravity_icon, "scale", Vector2(1.4, 1.4), 0.1)
	tween.tween_property(gravity_icon, "scale", Vector2(1.0, 1.0), 0.1)

func _update_gravity_icon(gravity_dir: int) -> void:
	# 1 = normal (gravity points down, arrow points down -> rot 0)
	# -1 = inverted (gravity points up, arrow points up -> rot PI)
	var target_rotation = 0.0 if gravity_dir == 1 else PI
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(gravity_icon, "rotation", target_rotation, 0.25)
