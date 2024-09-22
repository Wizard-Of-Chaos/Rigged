extends FmodBankLoader

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

	
func make_one_shot(node: Node, event_name: String, params: Dictionary, attached: bool = true, ):
	#this will be changed, this is just so the audio actually plays
	var sfx = FmodEventEmitter3D.new()
	sfx.set_attached(attached)
	sfx.set_auto_release(true) #this deletes the node after it plays once
	sfx.set_autoplay(true)
	sfx.set_event_name(event_name)
	for name in params:
		sfx.set_parameter(name, params[name])
	node.add_child(sfx)
