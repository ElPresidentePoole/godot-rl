extends Panel

@onready var item_labels: VBoxContainer = $ItemLabels

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_player_obtained_new_item(item_name, item_occupying_slot):
	var l: Button = Button.new()
	l.text = '{letter}) {name}'.format({'letter': Globals.ALPHABET[item_occupying_slot-1], 'name': item_name})
	item_labels.add_child(l)
