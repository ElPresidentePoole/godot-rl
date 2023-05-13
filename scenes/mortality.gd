extends Node

class_name Mortality

@export var max_hp: int
var hp: int
@onready var mortal: Node = get_parent()

signal died(he_who_had_their_mortality_clarified: Node2D)
signal hurt() # hp_changed, healed signals?

func _ready() -> void:
	self.hp = max_hp
	self.max_hp = max_hp

func take_damage(dh: int) -> void:
	self.hp -= dh
	emit_signal('hurt') # check if dh is 0?
	if self.hp <= 0:
		emit_signal('died', self.mortal)
