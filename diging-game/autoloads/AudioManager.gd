extends Node

var sfx_paths: Dictionary[String, String] = {
	"rocket": "res://assets/sfx/rocket.mp3",
	"drilling": "res://assets/sfx/drilling.mp3",
	"block_break": "res://assets/sfx/block_break.wav",
	"ui_click": "res://assets/sfx/ui_click.mp3",
	"money": "res://assets/sfx/money.mp3",
}
 
var music_paths: Dictionary[String, String] = {
	#"test": "res://assets/audio/test.mp3",
	# Same format as `sfx_paths`
	"silly": "uid://bkajxklo0m7ne"
}

var music_player: AudioStreamPlayer

var current_music_name: String = ""


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)


func _on_music_finished() -> void:
	# play on loop
	if current_music_name != "":
		music_player.play()


# SFX

func play_sfx(sfx_name: String, loop: bool = false, volume_db: float = 0.0, pitch_scale: float = 1.0) -> AudioStreamPlayer:
	if not sfx_paths.has(sfx_name):
		push_warning("AudioManager: no SFX registered for '%s'" % sfx_name)
		return null

	var stream: AudioStream = load(sfx_paths[sfx_name])
	if stream == null:
		push_warning("AudioManager: failed to load SFX at '%s'" % sfx_paths[sfx_name])
		return null

	if loop:
		stream = stream.duplicate()
		if "loop" in stream:
			stream.loop = true

	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.bus = "SFX"

	add_child(player)
	player.play()

	if loop:
		# Fallback for streams without a native loop flag (e.g. WAV):
		# restart whenever playback finishes. Never auto-frees.
		player.finished.connect(player.play)
	else:
		# Auto-cleanup once the sound finishes playing.
		player.finished.connect(player.queue_free)

	return player


## Stops a specific SFX player (looping or not) and frees it.
func stop_sfx(player: AudioStreamPlayer) -> void:
	if is_instance_valid(player):
		player.stop()
		player.queue_free()


func stop_all_sfx() -> void:
	for child in get_children():
		if child is AudioStreamPlayer and child != music_player:
			child.stop()
			child.queue_free()


# Music

func play_music(music_name: String, restart_if_same: bool = false) -> void:
	if not music_paths.has(music_name):
		push_warning("AudioManager: no music registered for '%s'" % music_name)
		return

	if music_name == current_music_name and not restart_if_same:
		if not music_player.playing:
			music_player.play()
		return

	var stream: AudioStream = load(music_paths[music_name])
	if stream == null:
		push_warning("AudioManager: failed to load music at '%s'" % music_paths[music_name])
		return

	music_player.stream = stream
	current_music_name = music_name
	music_player.play()


func stop_music() -> void:
	music_player.stop()
	current_music_name = ""


# Registration helpers

func register_sfx(sfx_name: String, path: String) -> void:
	sfx_paths[sfx_name] = path


func register_music(music_name: String, path: String) -> void:
	music_paths[music_name] = path
