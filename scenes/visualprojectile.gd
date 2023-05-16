extends Node2D

var dest: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	await create_tween().tween_property(self, 'position', dest, 0.1).finished
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
