class_name Action extends Node

var actor: Node

func _init(actor: Node) -> void:
	self.actor = actor

func perform(parent: Node) -> void:
	pass
