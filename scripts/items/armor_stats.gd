extends Resource
class_name ArmorStats

@export var id: int
@export var name: String
@export var defense: int
@export var durability: int = 100 
@export var resistance: Dictionary = {
	"physical": 1.0,  
	"energy": 1.0,
	"fire": 1.0,
	"ice": 1.0,
	"explosive": 1.0
}
