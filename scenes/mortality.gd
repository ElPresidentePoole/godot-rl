extends Node

class_name Mortality

var max_hp: int
var hp: int
var mortal: Node

signal died(he_who_had_their_mortality_clarified: Node2D)
signal hurt() # hp_changed, healed signals?

func _init(mortal: Node, hp: int):
	self.hp = hp
	self.max_hp = hp
	self.mortal = mortal

func take_damage(dh: int) -> void:
	self.hp -= dh
	emit_signal('hurt') # check if dh is 0?
	if self.hp <= 0:
		emit_signal('died', self.mortal)
