extends Node2D

class_name Actor

signal hovered_over(who: String)

@onready var mortality: Mortality = $Mortality
@onready var label: Label = $Label
@onready var attack_sound: AudioStreamPlayer2D = $AttackSound
@onready var actor_name: String = "Unnamed Actor"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func play_movement_tween(world_pos_final: Vector2) -> void:
	await create_tween().tween_property(self, 'position', world_pos_final, 0.1).finished

func _on_mouse_over_area_mouse_entered():
	HUDSignalBus.emit_signal("actor_hovered_over", actor_name)
	print_debug(actor_name)

func _on_mouse_over_area_mouse_exited():
	HUDSignalBus.emit_signal("actor_hovered_over", '')
