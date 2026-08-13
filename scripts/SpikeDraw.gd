## SpikeDraw.gd
## Node2D sederhana yang menggambar placeholder visual duri (segitiga)
## menggunakan _draw(). Tidak memerlukan aset gambar eksternal.
##
## Parent (Spike.gd) memanggil queue_redraw() setelah @export diubah
## agar warna / ukuran langsung terlihat di editor.

extends Node2D

## Referensi ke Spike parent untuk membaca parameter @export.
## Otomatis diisi di _ready(); Anda tidak perlu mengatur ini manual.
var _spike: Node2D


func _ready() -> void:
	_spike = get_parent().get_parent()  # Visual -> Spike


func _draw() -> void:
	if not is_instance_valid(_spike):
		return

	var w: float = _spike.spike_width
	var h: float = _spike.spike_height
	var col: Color = _spike.spike_color

	# Koordinat lokal:
	#   Alas duri ada di y = 0 (posisi Spike di dunia = titik alas).
	#   Ujung tajam menunjuk ke atas (y negatif).
	var tip   := Vector2(0.0,      -h)
	var left  := Vector2(-w * 0.5,  0.0)
	var right := Vector2( w * 0.5,  0.0)

	draw_colored_polygon(PackedVector2Array([tip, left, right]), col)

	# Outline tipis agar lebih jelas di editor.
	draw_polyline(
		PackedVector2Array([tip, left, right, tip]),
		col.darkened(0.4),
		1.5
	)
