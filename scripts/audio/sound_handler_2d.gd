extends FmodEventEmitter2D
#use for ui and music, anything non-positional

# Called when the node enters the scene tree for the first time.

var _fade_time = 0.334
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#if _fading_out and self.get_volume() == 0:
		#emit_signal("silent")
		

func make_one_shot(event_name: String, params: Dictionary = {}, attached: bool = true):
	self.sfx.set_auto_release(true) #this deletes the node after it plays once
	self.set_event_name(event_name)
	for name in params:
		self.set_parameter(name, params[name])
		
func make_loop(event_name: String, params: Dictionary = {}, attached: bool = true):
	self.set_event_name(event_name)
	self.set_attached(attached)
	for name in params:
		self.set_parameter(name, params[name])
		

func fade_in() -> void:
	if self.get_parameter("fade") != null:
		#self.set_allow_fadeout(true)
		self.set_parameter("fade", 1)
		self._fading_out = false
		get_tree().create_timer(_fade_time).timeout.connect(self._on_faded_out)
		
func fade_out() -> void:
	if self.get_parameter("fade") != null:
		#self.set_allow_fadeout(true)
		self.set_parameter("fade", 0)
		self._fading_out = true
		
func _on_faded_out():
	emit_signal("silenced")
		
		
		
	
		
