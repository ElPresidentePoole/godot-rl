class_name AttackAction extends Action

var damage: int
var victim: Actor

func _init(actor: Actor, victim: Actor, damage: int) -> void:
	super(actor)
	self.victim = victim
	self.damage = damage

func possible(parent: Node) -> bool:
	return self.victim.mortality.is_alive() and not self.actor.is_alive()

# TODO: only await/tween when in view /will be in view of player
func perform(parent: Node) -> void:
	# TODO: use weapons (verbs, damage, etc)!
	self.victim.mortality.take_damage(self.damage)
	HUDSignalBus.emit_signal("new_journal_entry", "%s attacks %s for %s damage!" % [self.actor, self.victim, self.damage])
	emit_signal("action_completed", self)
