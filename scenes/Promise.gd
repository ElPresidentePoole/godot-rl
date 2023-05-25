class_name Promise extends Node

var remaining: int

signal resolved()


func _init(signals: Array[Signal]) -> void:
	self.remaining = signals.size()
	print_debug('Promise made for {r} signals'.format({'r': remaining}))
	for s in signals:
		var t: Thread = Thread.new()
		t.start(func():
			await s
			remaining -= 1
			print_debug('{rand} free! {r}'.format({'rand': randi(), 'r': remaining}))
			if remaining == 0:
				print_debug('resolved')
				emit_signal("resolved"))
		t.wait_to_finish()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
