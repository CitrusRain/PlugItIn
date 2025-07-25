extends BaseMob
class_name Dog


@onready var dog_targets = get_tree().get_nodes_in_group("dog_targets")
var previous_target
var previous_play_point_pos: Vector3
var new_play_point: Vector3
var deposit_type = general_functions.item_types.WILD

func _ready() -> void:
	#if $Options:
		#var options = $Options.get_children()
		#for option in options:
			#option.visible = false
		#options[randi() % options.size()].visible = true
		#for option in options:
			#if option.visible == false:
				#option.queue_free()
			#else:
				#hold_point = option.get_child(0)
		#pass
	#else:
		#hold_point = $SmallDog/HoldPoint
	hold_point = $SmallDog/HoldPoint #remove if options are added and the above undocumented
	previous_play_point_pos = position
	find_something_to_do()

func _process(_delta: float) -> void:
	if activity == state_machine.SIT:
		target = go_sit_down
		looking_for_target = false
		navigation_agent_3d.target_position = target.global_position
		timeout()
	#elif  activity == state_machine.FETCH:
		#TODO: Rework FETCH logic to state machine
		#pass
	else:	
		if mob_inventory.get_child_count() != 0:
			position_item()
			if mob_inventory.get_child(0).pickup_type == general_functions.item_types.DOG_POOP:
				var mine = mob_inventory.get_child(randi() % mob_inventory.get_child_count())
				mine.reparent(get_tree().get_first_node_in_group("Mess"))
				mine.visible = true
				mine.done_with = false
			pass
		elif mob_inventory.get_child_count() == 0 :
			if target:
				pass
			else:
				find_something_to_do()
			navigation_agent_3d.target_position = target.global_position
		
		mob_interact.check_interactions()
	if mob_inventory.get_child_count() > 0:
		if mob_inventory.get_children()[0] is PerishableFood:
			if randi() % 20 == 1:
				eat(mob_inventory.get_children()[0])

func _physics_process(delta: float) -> void:
	if not looking_for_target:
		var next_position = navigation_agent_3d.get_next_path_position()
		
		if next_position.distance_to(navigation_agent_3d.get_final_position()) < 2 and attention_span.is_stopped():
		#if next_position == navigation_agent_3d.get_final_position():
			attention_span.wait_time = 1+ randi() % 15
			attention_span.start()
		elif next_position.distance_to(navigation_agent_3d.get_final_position()) < 2:
			pass
		else:
			attention_span.stop()
		var direction = global_position.direction_to(next_position)
		
		#var new_play_point = navigation_agent_3d.get_final_position()
		
		var i = 0
		while previous_play_point_pos.distance_to($PlayPoint.position) < 5.0 \
			and i < 400:
		#check distance and don't let the new one match the old one
			find_somewhere_to_play()
			#print("new point is " , new_play_point , "; distance to new point is ", previous_play_point_pos.distance_to(new_play_point))
			i += 1
		
		
		if previous_play_point_pos != new_play_point:
			previous_play_point_pos = $PlayPoint.position
			$PlayPoint.position = new_play_point
		
		# Add the gravity.
		if not is_on_floor():
			velocity.y -= gravity * delta
	
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
		move_and_slide()

func find_somewhere_to_play():
	navigation_agent_3d.target_position = NavigationServer3D.map_get_random_point(get_tree().get_first_node_in_group("NavigationMap").get_navigation_map(), 1, true) 
	#print(navigation_agent_3d.target_position)
	$PlayPoint.position = navigation_agent_3d.target_position

func _on_attention_span_timeout() -> void:
	if activity == state_machine.PLAY:
		if mob_inventory.get_child_count() > 0:
			var mine = mob_inventory.get_child(randi() % mob_inventory.get_child_count())
			mine.reparent(get_tree().get_first_node_in_group("Mess"))
			mine.visible = true
			mine.done_with = false
		find_something_to_do()
		if randi() % 10 >= 2:
			var poo = poop.instantiate()
			poo.pickup_type = general_functions.item_types.DOG_POOP
			add_child(poo)
			poo.reparent(get_tree().get_first_node_in_group("Mess"))


func find_something_to_do():
	target = dog_targets[randi() % dog_targets.size()]
	if target is not ItemGenerator: 
		if not (target.deposit_type == general_functions.item_types.WILD \
		or target.deposit_type == general_functions.item_types.DOG_POOP \
		or target.deposit_type == general_functions.item_types.DOG_TOY):
			find_something_to_do()

func _on_timeout_timer_timeout() -> void:
	activity = state_machine.PLAY
	find_something_to_do()
