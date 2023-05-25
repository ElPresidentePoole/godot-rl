extends ScrollContainer

class_name LogContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	HUDSignalBus.connect('new_journal_entry', add_entry)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func add_entry(msg: String):
#	if get_child_count() > 0 and get_child(0).text
# TODO: duplicates should be marked as xN (i.e. 'you shoot x5')
	var l = Label.new()
	l.text = msg
	$EntryContainer.add_child(l)
	$EntryContainer.move_child(l, 0)
#	$EntryContainer.reverse
