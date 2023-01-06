extends Sprite

export var up_neighbours: Array
export var left_neighbours: Array
export var down_neighbours: Array
export var right_neighbours: Array

var neighbours = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	neighbours["up"] = up_neighbours
	neighbours["left"] = left_neighbours
	neighbours["down"] = down_neighbours
	neighbours["right"] = right_neighbours


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
