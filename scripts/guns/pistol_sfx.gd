extends FmodBankLoader

#pistol fire:
const FIRE_EVENT_ID = "event:/sfx/players/weapons/placeholder_gun/placeholder_gun"

@export var room_muffling = "close"
@export var reverb = "medium_room"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func fire():
	var sfx = FmodEventEmitter3D.new()
	sfx.attached=true
	sfx.auto_release = true #this deletes the node after it plays once
	sfx.autoplay = true
	sfx.event_name = FIRE_EVENT_ID
	sfx.set_parameter("room_muffling", room_muffling)
	sfx.set_parameter("reverb", reverb)
	add_child(sfx)
