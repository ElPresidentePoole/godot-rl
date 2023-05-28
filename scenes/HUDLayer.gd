class_name HUDLayer extends CanvasLayer

@onready var hp_label: Label = $Labels/HP
@onready var gold_label: Label = $Labels/Gold
@onready var turn_label: Label = $Labels/Turn
@onready var floor_label: Label = $Labels/Floor
@onready var inventory_label: Label = $Labels/InventorySpace
@onready var inventory_panel: Panel = $InventoryPanel
@onready var curtains: Label = $Labels/Floor
@onready var log_container: ScrollContainer = $LogContainer
@onready var hovered_over_label: Label = $HoveredOver

# Called when the node enters the scene tree for the first time.
func _ready():
	HUDSignalBus.connect("actor_hovered_over", func(s: String):
		hovered_over_label.text = s)
	HUDSignalBus.connect("new_turn", func(t: int):
		turn_label.text = 'Turn: {t}'.format({'t': t}))
	HUDSignalBus.connect("new_floor", func(f: int):
		floor_label.text = 'Floor: {f}'.format({'f': f}))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
