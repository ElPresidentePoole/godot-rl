extends CanvasLayer

@onready var hp_label: Label = $Labels/HP
@onready var gold_label: Label = $Labels/Gold
@onready var turn_label: Label = $Labels/Turn
@onready var floor_label: Label = $Labels/Floor
@onready var inventory_label: Label = $Labels/InventorySpace
@onready var inventory_panel: Panel = $InventoryPanel
@onready var curtains: Label = $Labels/Floor
@onready var log_container: ScrollContainer = $LogContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
