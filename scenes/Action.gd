class_name Action extends Node

signal action_completed(this: Action)
var actor: Node

func _init(actor: Node) -> void:
	self.actor = actor

func possible(parent: Node) -> bool:
	return true

# TODO: Should do the action and returns true if the action was successfully completed, and false otherwise
# Really only matters for the player, as AI will not attempt to perform impossible actions.
func perform(parent: Node) -> void:
	emit_signal("action_completed", self)
