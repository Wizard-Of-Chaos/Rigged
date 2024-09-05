class_name AnimationController

var move_tween: Tween
var aim_tween: Tween
var anim_tree: AnimationTree

func set_tree(tree: AnimationTree):
	anim_tree = tree

func _on_set_movestate(_movestate: MoveState):
	if move_tween:
		move_tween.kill()
	move_tween = anim_tree.create_tween()
	move_tween.tween_property(anim_tree, "parameters/move_blend/blend_position", _movestate.id, .25)
	move_tween.parallel().tween_property(anim_tree, "parameters/move_anim_speed/scale", _movestate.animation_speed, .7)

func _on_set_playerstate(_playerstate: PlayerState):
	if aim_tween:
		aim_tween.kill()
	aim_tween = anim_tree.create_tween()
	var blend_factor = 0
	if _playerstate.name == "weapon_aiming":
		blend_factor = 1
	aim_tween.tween_property(anim_tree, "parameters/aim_blend/blend_amount", blend_factor, .15)
