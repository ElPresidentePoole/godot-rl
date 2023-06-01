class_name AttackAction extends Action

var damage: int
var victim: Actor

func _init(actor: Actor, victim: Actor, damage: int) -> void:
	super(actor)
	self.victim = victim
	self.damage = damage

func possible(parent: Node) -> bool:
	return self.victim.mortality.is_alive() and self.actor.mortality.is_alive()

# TODO: only await/tween when in view /will be in view of player
func perform(parent: Node) -> void:
	# TODO: use weapons (verbs, damage, etc)!
	HUDSignalBus.emit_signal("new_journal_entry", "%s attacks %s for %s damage!" % [self.actor.actor_name, self.victim.actor_name, self.damage])
	self.victim.mortality.take_damage(self.damage)
	emit_signal("action_completed", self)
