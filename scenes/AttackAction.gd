class_name AttackAction extends Action

var damage: int
var victim: Actor

func _init(actor: Actor, victim: Actor, damage: int) -> void:
	super(actor)
	self.victim = victim
	self.damage = damage

func possible(parent: Node) -> bool:
	return true

# TODO: only await/tween when in view /will be in view of player
func perform(parent: Node) -> void:
	emit_signal("action_completed", self)
