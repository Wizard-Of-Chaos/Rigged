class_name AnimationController

var tween: Tween
var anim_tree: AnimationTree

func set_tree(tree: AnimationTree):
	anim_tree = tree

func _on_set_movestate(_movestate: MoveState):
	if tween:
		tween.kill()
	tween = anim_tree.create_tween()
	tween.tween_property(anim_tree, "parameters/move_blend/blend_position", _movestate.id, .25)
	tween.parallel().tween_property(anim_tree, "parameters/move_anim_speed/scale", _movestate.animation_speed, .7)
