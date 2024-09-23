extends FmodEventEmitter3D
#Use for anything positional
@onready var event_id : String = self.get_event_name()
@onready var event_gu : String = self.get_event_guid()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:\
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func make_one_shot(event_name: String, params: Dictionary = {}, attached: bool = true):
	self.set_auto_release(true) #this deletes the node after it plays once
	self.set_attached(attached)
	self.set_event_name(event_name)
	#self.set_preload_event(true)
	for name in params:
		self.set_parameter(name, params[name])
	self.play()
	
func make_loop(event_name: String, params: Dictionary = {}, attached: bool = true):
	self.set_event_name(event_name)
	self.set_attached(attached)
	#self.set_preload_event(true)
	for name in params:
		self.set_parameter(name, params[name])
	
