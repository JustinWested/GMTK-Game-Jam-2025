extends AnimationPlayer

func _ready():
	_create_basic_animations()

func _create_basic_animations():
	# Walk animation
	var walk_anim = Animation.new()
	walk_anim.length = 1.0
	walk_anim.loop_mode = Animation.LOOP_LINEAR
	
	var track_idx = walk_anim.add_track(Animation.TYPE_POSITION_3D)
	walk_anim.track_set_path(track_idx, "^..:position")
	walk_anim.position_track_insert_key(track_idx, 0.0, Vector3(0, 1, 0))
	walk_anim.position_track_insert_key(track_idx, 1.0, Vector3(0, 1, -2))
	
	add_animation("walk", walk_anim)
	
	# Idle animation
	var idle_anim = Animation.new()
	idle_anim.length = 2.0
	idle_anim.loop_mode = Animation.LOOP_LINEAR
	
	track_idx = idle_anim.add_track(Animation.TYPE_ROTATION_3D)
	idle_anim.track_set_path(track_idx, "^..:rotation")
	idle_anim.rotation_track_insert_key(track_idx, 0.0, Vector3(0, 0, 0))
	idle_anim.rotation_track_insert_key(track_idx, 1.0, Vector3(0, 0.2, 0))
	idle_anim.rotation_track_insert_key(track_idx, 2.0, Vector3(0, 0, 0))
	
	add_animation("idle", idle_anim)
	
	# Point gun animation
	var point_anim = Animation.new()
	point_anim.length = 0.5
	
	track_idx = point_anim.add_track(Animation.TYPE_ROTATION_3D)
	point_anim.track_set_path(track_idx, "^../RobberVisuals:rotation")
	point_anim.rotation_track_insert_key(track_idx, 0.0, Vector3(0, 0, 0))
	point_anim.rotation_track_insert_key(track_idx, 0.5, Vector3(0, -1.5, 0))
	
	add_animation("point_gun", point_anim)