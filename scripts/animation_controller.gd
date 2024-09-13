class_name AnimationController

var move_tween: Tween
var aim_tween: Tween
var anim_tree: AnimationTree

func set_tree(tree: AnimationTree):
	anim_tree = tree

func _on_set_move_state(move_state: MoveState):
	if move_tween:
		move_tween.kill()
	move_tween = anim_tree.create_tween()
	move_tween.tween_property(anim_tree, "parameters/move_blend/blend_position", move_state.id, .25)
	move_tween.parallel().tween_property(anim_tree, "parameters/move_anim_speed/scale", move_state.animation_speed, .7)

func _on_set_player_state(player_state: PlayerStateChange):
	if aim_tween:
		aim_tween.kill()
	aim_tween = anim_tree.create_tween()
	var blend_factor = 0
	if player_state.new_state.name == "weapon_aiming":
		blend_factor = 1
	aim_tween.tween_property(anim_tree, "parameters/aim_blend/blend_amount", blend_factor, .15)
