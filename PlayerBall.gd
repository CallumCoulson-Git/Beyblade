extends RigidBody3D

@export var speed = 10

@export var RotationTorque = 5

@export var MaxStamina = 100

@export var Stamina = 50

@export var InitialWeight = 2

@export var InitialDamp = 0.05

@export var MaxJumps = 1

@export var Lives = 3

@export var isBlocking = false

@onready var camera : ThirdPersonCamera = $ThirdPersonCamera

var InitialTransform = transform.basis
var jumps = 0

var hitsound2 = preload("res://Resources/sounds/metal-dagger-hit-185444.mp3")
var hitsound3 = preload("res://Resources/sounds/sword-01-108326.mp3")
var hitsound4 = preload("res://Resources/sounds/sword-hit-7160.mp3")
var hitsounds = [hitsound2,hitsound3,hitsound4]
var spinsound = preload("res://Resources/sounds/spinloop.mp3")


func _ready():
	if is_multiplayer_authority():
		$ThirdPersonCamera.current = true
	
func _enter_tree():
	set_multiplayer_authority(name.to_int())
	if is_multiplayer_authority():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		


func _process(_delta):
	pass
	

func _physics_process(_delta):
	var Channeling = 1
	var StaminaChange = 0
	var WeightChange = 0
	$SpinSound.pitch_scale = lerp($SpinSound.pitch_scale,  0.4 + (angular_velocity.y / 40),0.1)
	$SpinSound.volume_db = lerp($SpinSound.volume_db,  -80 + (angular_velocity.y),0.1)

	$SpinSound.max_db = clamp(lerp($SpinSound.max_db,  -50 + (angular_velocity.y ),0.1), -50, 0)

	if !$SpinSound.playing:
		$SpinSound.stream = spinsound
		$SpinSound.stream.loop = true
		$SpinSound.play
	
	if is_multiplayer_authority() && Lives > -1:
		if Input.is_action_pressed("move_forward"):
			var dir = camera.get_front_direction()
			apply_central_force(dir * speed)
		if Input.is_action_pressed("move_back"):
			var dir = camera.get_back_direction()
			apply_central_force(dir * speed)
		if Input.is_action_pressed("move_left"):
			var dir = camera.get_left_direction()
			apply_central_force(dir * speed)
		if Input.is_action_pressed("move_right"):
			var dir = camera.get_right_direction()
			apply_central_force(dir * speed)
			
		if Input.is_action_just_pressed("mouse_wheel_down"):
			print_debug()
			$ThirdPersonCamera.distance_from_pivot += 0.5
		if Input.is_action_just_pressed("mouse_wheel_up"):
			$ThirdPersonCamera.distance_from_pivot -= 0.5
		if Input.is_action_just_pressed("jump"):
			if jumps != 0 :
				if Stamina > 15:
					StaminaChange -= 15
					apply_impulse(Vector3(0,15,0))
					jumps -= 1
				
		if Input.is_action_pressed("mouse_1"):
			if Stamina > 2:
				Channeling = 3
				WeightChange += -1
				StaminaChange -=2
				
		if Input.is_action_pressed("mouse_2"):
			if Stamina > 2:
				WeightChange += 3
				StaminaChange -=2
				isBlocking = true
		else:
			isBlocking = false
				
				
		if Input.is_action_just_pressed("shift"):
			if Stamina > 20:
				var dashDir = camera.get_front_direction()
				apply_impulse(dashDir * 20)
				StaminaChange -=20
				
		if Input.is_action_just_pressed("respawn"):
			respawn()
			
		if get_contact_count() > 0:
			var contacts = get_colliding_bodies()
			jumps = clamp(jumps + 1, 0, MaxJumps)
			for contact in contacts:
				if contact.name == "Deathplane":
					respawn()
				
					
			
		
		changeColour(Channeling)
		
		staminaManagement(StaminaChange)
		
		weightChange(WeightChange)
		
		blockingVisual()
		
		houseKeeping()
		
	if get_contact_count() > 0:
		var contactsSparks = get_colliding_bodies()
		for contactSparks in contactsSparks:
			if contactSparks.name == "PlayerRigidBody":
				var midPoint = lerp(position, contactSparks.position,0.5)
				$sparkLocation/Sparks.emitting = true
				$sparkLocation.set_global_position(midPoint)
				
				$Hitsounds.pitch_scale = 1 + randf()*0.4
				$Hitsounds.stream = hitsounds.pick_random()
				$Hitsounds.play()
				
			else:
				$sparkLocation/Sparks.emitting = false
				
	if Lives > -1:
		apply_torque(Vector3(0, RotationTorque * Channeling, 0))
	
	
	
func changeColour(Channeling):
	if Channeling > 1:
		$CanvasLayer/RPMLABEL.label_settings.set_font_color(Color(1,0.2,0.2,1))
	else:
		$CanvasLayer/RPMLABEL.label_settings.set_font_color(Color(1,1,1,1))


func staminaManagement(adjustment = 0):
	if is_multiplayer_authority():
		
		adjustment += angular_velocity.y / 80
		
		Stamina = clamp(Stamina + adjustment,0,MaxStamina)
		
		$CanvasLayer/Control/StaminaBar.set_value(Stamina)
	

func weightChange(change):
	var NewMass = InitialWeight + change
	mass = lerp(mass,float(NewMass),0.1)
	
	

func respawn():
	Lives -= 1
	if Lives == 2:
		$CanvasLayer/Lives.text = "II"
	elif Lives == 1:
		$CanvasLayer/Lives.text = "I"
	else:
		$CanvasLayer/Lives.text = ""
		
	if Lives > -1:
		var mainNode = get_parent()
		set_position(mainNode.SpawnPoints.pick_random())
		set_rotation(Vector3(0,1,0))
		staminaManagement(-100)
	else:
		get_parent().find_child("SpectatorCam").set_current(true)

func blockingVisual():
	if isBlocking:
		$sphereMesh.get_active_material(0).set_albedo(Color(0, 0, 0, 1))
	else:
		var lerpColour = 0# $shieldMesh.get_active_material(0).get_albedo
		$sphereMesh.get_active_material(0).set_albedo(Color(1, 1, 1, 1))
	
func houseKeeping():
	angular_damp = InitialDamp * ((mass*2)-3)

	if angular_velocity.y < 10 && linear_velocity.length() < 1:
		mass = lerp(mass,mass * 0.2, 0.01)
	

func _unhandled_input(event):	
	if is_multiplayer_authority():
		if event.is_action_pressed("escape") :
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED :
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				camera.mouse_follow = false
			else :
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				camera.mouse_follow = true



func _on_area_3d_body_entered(body):
	Stamina = 0
	respawn()

