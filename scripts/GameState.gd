## GameState.gd
## Autoload singleton untuk Pijak Langit.
## Menyimpan state global: checkpoint, lives, score.
##
## Daftarkan di Project > Project Settings > Autoload:
##   Name: GameState
##   Path: res://scripts/GameState.gd

extends Node

# ---------------------------------------------------------------------------
# SIGNALS
# ---------------------------------------------------------------------------

## Dipancarkan setiap kali skor berubah. HUD connect ke signal ini.
signal score_changed(new_score: int)

## Dipancarkan setiap kali lives berubah (pickup health item).
signal lives_changed(new_lives: int)

# ---------------------------------------------------------------------------
# CHECKPOINT STATE
# ---------------------------------------------------------------------------

## Posisi checkpoint terakhir yang disentuh Player.
## Nil berarti belum ada checkpoint – player respawn di spawn_position.
var current_checkpoint_position: Vector2 = Vector2.ZERO

## Gravity direction saat checkpoint disentuh (1 = normal, -1 = terbalik).
var current_checkpoint_gravity: int = 1

## Apakah checkpoint sudah pernah disentuh dalam sesi ini.
var checkpoint_active: bool = false

## Posisi spawn awal level (diset oleh Player._ready() atau Level).
## Digunakan sebagai fallback bila belum ada checkpoint.
var level_spawn_position: Vector2 = Vector2.ZERO

# ---------------------------------------------------------------------------
# PLAYER STATS
# ---------------------------------------------------------------------------

## Jumlah nyawa. Game over saat lives mencapai 0.
var lives: int = 3

## Batas maksimum lives yang bisa dimiliki player.
const MAX_LIVES: int = 3

## Skor saat ini.
var score: int = 0

# ---------------------------------------------------------------------------
# PUBLIC API
# ---------------------------------------------------------------------------

## Simpan checkpoint baru.
func save_checkpoint(pos: Vector2, gravity_dir: int) -> void:
	current_checkpoint_position = pos
	current_checkpoint_gravity  = gravity_dir
	checkpoint_active           = true
	print("[GameState] Checkpoint disimpan: pos=%s, gravity=%d" % [pos, gravity_dir])


## Kembalikan posisi respawn yang efektif.
## Jika belum ada checkpoint, kembalikan level_spawn_position.
func get_respawn_position() -> Vector2:
	if checkpoint_active:
		return current_checkpoint_position
	return level_spawn_position


## Kembalikan gravity_direction efektif untuk respawn.
func get_respawn_gravity() -> int:
	if checkpoint_active:
		return current_checkpoint_gravity
	return 1


## Kurangi lives sebesar 1. Kembalikan sisa lives.
func consume_life() -> int:
	lives = max(lives - 1, 0)
	emit_signal("lives_changed", lives)
	return lives


## Tambah skor sebesar jumlah tertentu dan emit signal score_changed.
func add_score(amount: int = 1) -> void:
	score += amount
	emit_signal("score_changed", score)
	print("[GameState] Score +%d → %d" % [amount, score])


## Tambah lives sebesar 1, tidak melebihi MAX_LIVES.
## Emit signal lives_changed.
func add_life(amount: int = 1) -> void:
	if lives < MAX_LIVES:
		lives = min(lives + amount, MAX_LIVES)
		emit_signal("lives_changed", lives)
		print("[GameState] Lives +%d → %d" % [amount, lives])
	else:
		print("[GameState] Lives sudah maksimum (%d), item tidak diserap." % MAX_LIVES)


## Reset seluruh state (panggil saat load level baru / new game).
func reset() -> void:
	current_checkpoint_position = Vector2.ZERO
	current_checkpoint_gravity  = 1
	checkpoint_active           = false
	level_spawn_position        = Vector2.ZERO
	lives                       = 3
	score                       = 0
	print("[GameState] State direset.")
