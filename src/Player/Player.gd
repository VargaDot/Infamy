extends KinematicBody2D

var speed = 500

var walkSpeed = 500
var runSpeed = 1000

var health = 100
var armor = 100
var stamina = 100

var current_weapon = -1

var weapons: Array = []

var weapon1_offset: Dictionary = {
	"stand":0,
	"interact":-10,
	"light":-10,
	"heavy":-30
}

var bag_offset: Dictionary = {
	"stand":0,
	"interact":-25,
	"light":-20,
	"heavy":-50
}

var velocity: Vector2 = Vector2.ZERO

func _ready():
	Game.player = self
	Game.player_status = Game.player_statuses.NORMAL

	$Bag.hide()
	
	weapons.append(load(Global.weapon_scene_paths[Game.player_weapons[0]]).instance())
	add_child(weapons[0])
	move_child(weapons[0],0)
	weapons.append(load(Global.weapon_scene_paths[Game.player_weapons[1]]).instance())
	add_child(weapons[1])
	move_child(weapons[1],1)

func select_weapon(index: int) -> void:
	if (index != current_weapon):
		current_weapon = index
	else:
		current_weapon = -1
		
	Game.player_weapon = current_weapon
	if (current_weapon == -1):
		if (Game.player_disguise != "normal"):
			Game.player_status = Game.player_statuses.DISGUISED
		else:
			Game.player_status = Game.player_statuses.NORMAL
	else:
		Game.player_status = Game.player_statuses.ARMED
		
func get_input() -> void:
	var mouse_pos = get_global_mouse_position()
	
	if (global_position.distance_to(mouse_pos) >  5):
		look_at(mouse_pos)
		$Interaction_ray.look_at(mouse_pos)
		
	var xDir = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	var yDir = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
	
	if (!Game.player_is_interacting && !Game.player_is_reloading && !Game.player_is_meleing):
		if (Input.is_action_just_pressed("weapon1")):
			select_weapon(0)
		elif (Input.is_action_just_pressed("weapon2")):
			select_weapon(1)
			
		if (Input.is_action_pressed("shoot") && Game.player_can_shoot && current_weapon != -1):
			weapons[current_weapon].shoot()
				
		if (Input.is_action_just_pressed("reload") && Game.player_can_shoot && current_weapon != -1):
			if (!Game.player_is_running):
				weapons[current_weapon].reload()
				
		if (Input.is_action_just_pressed("drop") && Game.player_bag != "empty"):
			remove_bag()
			Game.spawn_bag()
			
		if (Input.is_action_pressed("sprint") && Game.player_can_run && stamina >= 10):
			use_stamina()
		elif (!Input.is_action_pressed("sprint") || !Game.player_can_run):
			recover_stamina()
	
	velocity = Vector2(xDir,yDir).normalized()

func use_stamina():
	if (stamina == 0):
		Game.player_can_run = false
		Game.player_is_running = false	
		speed = walkSpeed
		return
	
	elif (stamina > 0 && velocity != Vector2.ZERO):
		Game.player_is_running = true	
		if ($Stamina_use.is_stopped()):
			$Stamina_use.start()
				
		$Stamina_recovery.stop()
		if (stamina > 0):
			speed = runSpeed

func recover_stamina():
	if (stamina < 100):
		if ($Stamina_recovery.is_stopped()):
			$Stamina_recovery.start()
	else:
		$Stamina_recovery.stop()
	
	Game.player_is_running = false	
	$Stamina_use.stop()
	speed = walkSpeed	
	
func _on_Stamina_use_timeout():
	if (Game.player_is_interacting || velocity == Vector2.ZERO):
		Game.player_can_run = false
		recover_stamina()
		return
	
	if (stamina > 0):
		stamina -= 5
	else:
		Game.player_can_run = false


func _on_Stamina_recovery_timeout():
	if (stamina < 100):
		stamina += 1
		
	if (stamina > 10 && velocity != Vector2.ZERO):
		Game.player_can_run = true

func _physics_process(delta) -> void:
	if (!Game.game_process):
		return	

	get_input()
	
	if (Game.player_can_move):
		velocity = move_and_slide(velocity * speed)



func add_bag() -> void:
	$Bag.show()
	
func remove_bag() -> void:
	$Bag.hide()

func draw_player() -> void:
	if (Game.player_is_interacting):
		$Player_sprite.animation = Game.player_disguise + "_interact"
	elif (current_weapon != -1):
		if (current_weapon == 0):
			$Player_sprite.animation = Game.player_disguise + "_" + weapons[0].animation
		else:
			$Player_sprite.animation = Game.player_disguise + "_" + weapons[1].animation
	else:
		$Player_sprite.animation = Game.player_disguise + "_stand"

func draw_weapons() -> void:
	var plr_anim = $Player_sprite.animation.split("_")
	
	if (current_weapon == -1):
		if (weapons[0].is_weapon_visible):
			weapons[0].position = Vector2(-160 + weapon1_offset[plr_anim[1]],-15)
			weapons[0].rotation_degrees = 80
			weapons[0].show()
		else:
			weapons[0].hide()
		
		if (weapons[1].is_weapon_visible):
			weapons[1].position = Vector2(10,200)
			weapons[1].rotation_degrees = -15
			weapons[1].show()
		else:
			weapons[1].hide()
		
		move_child(weapons[0],0)
		move_child(weapons[1],1)
	elif (current_weapon == 0):		
		weapons[0].position = weapons[0].weapon_position
		weapons[0].rotation_degrees = 0
		weapons[0].show()
		
		if (weapons[1].is_weapon_visible):
			weapons[1].position = Vector2(10,200)
			weapons[1].rotation_degrees = -15
			weapons[1].show()
		else:
			weapons[1].hide()
		
		move_child(weapons[0],get_child_count() - 1)
		move_child(weapons[1],0)
	elif (current_weapon == 1):
		if (weapons[0].is_weapon_visible):
			weapons[0].position = Vector2(-160 + weapon1_offset[plr_anim[1]],-15)
			weapons[0].rotation_degrees = 80
			weapons[0].show()
		else:
			weapons[0].hide()
		
		weapons[1].position = weapons[1].weapon_position
		weapons[1].rotation_degrees = 0
		weapons[1].show()	
		
		move_child(weapons[0],0)
		move_child(weapons[1],get_child_count() - 1)
		
func draw_bag() -> void:
	if ($Bag.visible):
		var plr_anim = $Player_sprite.animation.split("_")
		
		$Bag.position = Vector2(-140 + bag_offset[plr_anim[1]],5)

func _process(delta) -> void:
	if (!Game.game_process):
		return
	
	print(Game.player_can_run,Game.player_is_running)
	
	draw_player()
	draw_weapons()
	draw_bag()
	
func _exit_tree():
	Game.player = null