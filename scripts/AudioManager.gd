extends Node
## AudioManager.gd
## Autoload singleton untuk mengatur BGM dan SFX di Pijak Langit.
##
## Daftarkan di Project > Project Settings > Autoload:
##   Name: AudioManager
##   Path: res://scripts/AudioManager.gd

const BUS_MASTER = "Master"
const BUS_BGM = "BGM"
const BUS_SFX = "SFX"

# Dictionary untuk menyimpan AudioStream BGM per bioma
# (Isi path res://... jika file sudah ada)
var bgm_dict: Dictionary = {
	"bgm_biome1": null, # preload("res://assets/audio/bgm/biome1.ogg"),
	"bgm_biome2": null,
	"bgm_biome3": null
}

# Dictionary untuk menyimpan AudioStream SFX
var sfx_dict: Dictionary = {
	"sfx_gravity_flip": null, # preload("res://assets/audio/sfx/gravity_flip.wav"),
	"sfx_collect": null,
	"sfx_death": null,
	"sfx_jump": null
}

# Nodes
var _bgm_player: AudioStreamPlayer
var _bgm_player_fade: AudioStreamPlayer # Untuk crossfade
var _sfx_players: Array[AudioStreamPlayer] = []
var _num_sfx_players: int = 8

# State
var current_bgm_name: String = ""

# Volume tersimpan (0.0 - 1.0)
var master_volume: float = 1.0
var bgm_volume: float = 1.0
var sfx_volume: float = 1.0

func _ready() -> void:
	_setup_buses()
	_setup_nodes()
	
	# Load settingan volume jika ada sistem save data nanti
	# _apply_all_volumes()

func _setup_buses() -> void:
	# Buat bus BGM jika belum ada
	if AudioServer.get_bus_index(BUS_BGM) == -1:
		AudioServer.add_bus()
		var idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, BUS_BGM)
		AudioServer.set_bus_send(idx, BUS_MASTER)
		
	# Buat bus SFX jika belum ada
	if AudioServer.get_bus_index(BUS_SFX) == -1:
		AudioServer.add_bus()
		var idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, BUS_SFX)
		AudioServer.set_bus_send(idx, BUS_MASTER)

func _setup_nodes() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = BUS_BGM
	add_child(_bgm_player)
	
	_bgm_player_fade = AudioStreamPlayer.new()
	_bgm_player_fade.bus = BUS_BGM
	add_child(_bgm_player_fade)
	
	for i in range(_num_sfx_players):
		var p = AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		_sfx_players.append(p)

## Mainkan SFX berdasarkan nama di dictionary
func play_sfx(sfx_name: String) -> void:
	if not sfx_dict.has(sfx_name):
		print("[AudioManager] SFX tidak terdaftar: ", sfx_name)
		return
		
	var stream = sfx_dict[sfx_name]
	if stream == null:
		# print("[AudioManager] Placeholder SFX dimainkan: ", sfx_name)
		return
		
	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.play()
			return
			
	print("[AudioManager] Semua SFX player sedang sibuk!")

## Mainkan BGM dengan crossfade jika sedang ada lagu yang main
func play_bgm(bgm_name: String, crossfade_duration: float = 1.0) -> void:
	if bgm_name == current_bgm_name:
		return
		
	if not bgm_dict.has(bgm_name):
		print("[AudioManager] BGM tidak terdaftar: ", bgm_name)
		return
		
	var new_stream = bgm_dict[bgm_name]
	current_bgm_name = bgm_name
	
	if _bgm_player.playing:
		# Tukar player untuk crossfade
		var temp = _bgm_player
		_bgm_player = _bgm_player_fade
		_bgm_player_fade = temp
		
		_bgm_player.stream = new_stream
		if new_stream != null:
			_bgm_player.play()
		_bgm_player.volume_db = -80.0
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(_bgm_player, "volume_db", 0.0, crossfade_duration)
		tween.tween_property(_bgm_player_fade, "volume_db", -80.0, crossfade_duration)
		tween.chain().tween_callback(_bgm_player_fade.stop)
	else:
		_bgm_player.stream = new_stream
		if new_stream != null:
			_bgm_player.play()
		_bgm_player.volume_db = 0.0

## Hentikan BGM dengan fade out
func stop_bgm(fade_duration: float = 1.0) -> void:
	current_bgm_name = ""
	if _bgm_player.playing:
		var tween = create_tween()
		tween.tween_property(_bgm_player, "volume_db", -80.0, fade_duration)
		tween.tween_callback(_bgm_player.stop)

# ---------------------------------------------------------------------------
# VOLUME CONTROLS (0.0 to 1.0)
# ---------------------------------------------------------------------------

func set_master_volume(vol: float) -> void:
	master_volume = clamp(vol, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index(BUS_MASTER)
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(master_volume))

func set_bgm_volume(vol: float) -> void:
	bgm_volume = clamp(vol, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index(BUS_BGM)
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(bgm_volume))

func set_sfx_volume(vol: float) -> void:
	sfx_volume = clamp(vol, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index(BUS_SFX)
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(sfx_volume))
