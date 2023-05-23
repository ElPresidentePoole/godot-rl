class_name Action extends Node

signal action_completed(this: Action)
var actor: Node

func _init(actor: Node) -> void:
	self.actor = actor

func perform(parent: Node) -> void:
	emit_signal("action_completed", self)
