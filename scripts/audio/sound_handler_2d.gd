extends FmodEventEmitter2D
#use for ui and music, anything non-positional

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

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
		
func fade_out() -> void:
	if self.get_parameter("fade") != null:
		#self.set_allow_fadeout(true)
		self.set_parameter("fade", 0)
		
		
		
	
		
