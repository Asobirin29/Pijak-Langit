## RespawnOverlay.gd
## Komponen UI overlay untuk efek fade out/fade in saat respawn.
## Node: CanvasLayer > ColorRect
##
## Cara pakai:
##   var overlay = RespawnOverlay.new()
##   add_child(overlay)
##   await overlay.do_respawn_fade(callable_lambda)

extends CanvasLayer

# ---------------------------------------------------------------------------
# CONSTANTS
# ---------------------------------------------------------------------------

## Durasi fade-out (layar menjadi hitam), detik.
const FADE_OUT_DURATION: float = 0.12

## Durasi fade-in (layar kembali bening), detik.
const FADE_IN_DURATION: float  = 0.15

## Total maksimal ≈ 0.27 detik (< 0.3 detik PRD).

# ---------------------------------------------------------------------------
# NODES
# ---------------------------------------------------------------------------

var _rect: ColorRect

# ---------------------------------------------------------------------------
# READY
# ---------------------------------------------------------------------------

func _ready() -> void:
	# Layer ini harus di atas segala sesuatunya.
	layer = 128

	_rect = ColorRect.new()
	_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)


# ---------------------------------------------------------------------------
# PUBLIC API
# ---------------------------------------------------------------------------

## Jalankan sekuens fade-out → callback → fade-in.
## [param respawn_callback]: Callable tanpa argumen, dipanggil saat layar gelap.
##
## Contoh:
##   await overlay.do_respawn_fade(func(): player.global_position = pos)
func do_respawn_fade(respawn_callback: Callable) -> void:
	# --- Fade OUT (menjadi hitam) ---
	var tween_out := create_tween()
	tween_out.set_ease(Tween.EASE_IN)
	tween_out.set_trans(Tween.TRANS_QUAD)
	tween_out.tween_property(_rect, "color", Color(0, 0, 0, 1), FADE_OUT_DURATION)
	await tween_out.finished

	# --- Eksekusi respawn ---
	respawn_callback.call()

	# --- Fade IN (kembali bening) ---
	var tween_in := create_tween()
	tween_in.set_ease(Tween.EASE_OUT)
	tween_in.set_trans(Tween.TRANS_QUAD)
	tween_in.tween_property(_rect, "color", Color(0, 0, 0, 0), FADE_IN_DURATION)
	await tween_in.finished
