extends ScrollContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func add_entry(msg: String):
	var l = Label.new()
	l.text = msg
	$EntryContainer.add_child(l)
	$EntryContainer.move_child(l, 0)
#	$EntryContainer.reverse
