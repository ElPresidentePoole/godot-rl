class_name Promise extends Node

var signals: Array[Signal]
var remaining: int

signal resolved()

func all() -> void:
	for s in self.signals:
		var t: Thread = Thread.new()
		t.start(func():
			await s
			remaining -= 1
			print_debug('free! {r}'.format({'r': remaining}))
			if remaining == 0:
				emit_signal("resolved"))
		t.wait_to_finish()

func _init(signals: Array[Signal]) -> void:
	self.remaining = signals.size()
	self.signals = signals

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
