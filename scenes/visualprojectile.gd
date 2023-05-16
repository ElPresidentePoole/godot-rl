extends Node2D

@onready var line: Line2D = $Line2D
var dest: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	line.add_point(Vector2(0, 0))
	line.add_point(dest-position)
	await get_tree().create_timer(0.1).timeout
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
