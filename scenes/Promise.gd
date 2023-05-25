class_name Promise extends Node

var remaining: int

signal resolved()

func add_signal(sig: Signal) -> void:
	remaining += 1
	await sig
	remaining -= 1
	if remaining == 0:
		emit_signal('resolved')

func _init() -> void:
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
