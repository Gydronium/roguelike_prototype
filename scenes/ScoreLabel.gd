extends Label


var _score: int = 0

const _score_text: String = "SCORE: "


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func setScore(score: int):
	_score = score
	text = _score_text + str(_score)

func add_score(score: int) :
	setScore(_score + score)

func reset_score():
	_score = 0
