extends FmodBankLoader


@onready var music_script = preload("res://scripts/audio/sound_handler_2d.gd")
#@onready var fade_out = $Fade
#make it nicer...
const bank_path = "res://assets/audio/Build/"
const fade_time = 0.34
var current_song: FmodEventEmitter2D = null
var fading_song: FmodEventEmitter2D = null


signal faded_out


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#fade_out.connect("timeout", self._on_fade_timeout)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func play_song(music_event):
	#if song is playing, let it fade out first
	if current_song != null:
		self.fade_out_song()
	current_song = FmodEventEmitter2D.new()
	current_song.set_script(music_script)
	current_song.make_loop(music_event, {}, false)
	self.add_child(current_song)
	current_song.play()
	
	
func fade_out_song():
	if current_song:
		#this really shouldn't happen, but if fading_song is still playing,
		#let's wait for it to fade out
		if fading_song:
			await faded_out
		fading_song = current_song
		current_song = null
		fading_song.set_parameter("fade", 0)
		await get_tree().create_timer(fade_time).timeout
		#fading song is silent, we're safe to murder it
		self.remove_child(fading_song)
		fading_song.queue_free()
		emit_signal("faded_out")
		
		
