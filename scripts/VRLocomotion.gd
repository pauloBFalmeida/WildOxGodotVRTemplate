@tool
extends Node
class_name VRPhysicsLocomotion

## A VR locomotion node that uses physics for ground detection and terrain following.
## Should be attached to an XROrigin3D to be used like a Movement Component (Node)

################################ Movement settings #############################
@export_group("Movement")

## Movement speed of the VRPlayer in meters per second
@export_range(0, 10, 0.001, "or_greater", "suffix:m/s", "hide_slider") 
var speed: float = 2.0 

## Enable/disable sprinting functionality
@export 
var allow_sprinting: bool = true: 
	set (value):
		allow_sprinting = value
		notify_property_list_changed() # Show/Hide sprint_multiplier amd toggle_sprint_mode
		
## How much faster sprinting is	(e.g., a multiplier of 3 and a base speed of 2 m/s, means sprinting speed would be 6 m/s (2*3)
@export 
var sprint_multiplier: float = 2.0

## If true, sprint is toggle based, if false, hold to sprint
@export 
var toggle_sprint_mode: bool = true  

## Ignore small thumbstick movements
@export 
var deadzone: float = 0.2  

## Gravity strength
@export_custom(PROPERTY_HINT_NONE, "suffix: m/s") 
var gravity: float = 9.8

## Enable/disable jumping functionality
@export 
var allow_jumping: bool = true:
	set (value):
		allow_jumping = value
		notify_property_list_changed() # Show/Hide jump_strength
		
## Jump force when jumping. Note that this is not how high you jump, but how hard you jump
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") 
var jump_strength: float = 4.0  

## Adjusts camera height: positive = higher, negative = lower
@export 
var hmd_height_offset: float = 0.0  

################################ Turning Settings ##############################
@export_group("Turning")

## Set to true for smooth turning, false for snap turning
@export var use_smooth_turning: bool = false: 
	set (value):
		use_smooth_turning = value
		notify_property_list_changed() # Show/Hide smooth_turn_speed
		
## How fast you can smoothly turn. Note: Value is displayed in the editor inspector as degrees per second 
## but it is stored as radians per second. Default value translates to 45 degrees per second
@export_range(0, 360, 0.001, "radians_as_degrees", "or_greater", "hide_slider", "suffix:°/s")
var smooth_turn_speed: float = 0.7853982

## How much you snap turn. Note: Value is displayed in the editor inspector as degrees but it is stored as
## radians. Default value translates to 30 degrees per snap turn. It is recommended you make the snap amount divide evenly into 360 degrees or 2pi rads
@export_range(0, 180, 0.001, "radians_as_degrees", "or_greater", "hide_slider") 
var snap_turn_amount: float = 0.5235988

## How long in seconds before we can snap turn again. If this value is less than or equal to 0, then
## the player can snap turn as fast as they like, but they must return the thumbstick inside the deadzone
## before they can snap turn once more
@export_range(0, 10, 0.001, "suffix:s", "hide_slider", "or_greater") 
var snap_turn_cooldown: float = 0.25

################################ CharacterBody3D settings ######################

## Extracted variables from the CharacterBody3D that will be created and named 'PhysicsBody' at runtime
@export_category("CharacterBody3D")

################################ Floor Settings ################################
@export_group("Floor")

## Maximum angle (in radians) where a slope is still considered a floor (or a ceiling), rather than a wall, when calling move_and_slide(). 
## The default value equals 85 degrees. The value in the editor inspector is shown in degrees for convenience 
@export_range(0, 10, 0.001, "radians_as_degrees", "hide_slider", "or_greater") 
var floor_max_angle: float = 1.48353:
	set (value): # Ensure the physics_body is also updated if this value is set at runtime
			floor_max_angle = value
			if physics_body and is_instance_valid(physics_body):
				# Defer a lambda function which updates the physics body. While this is not required doing so is safer
				(func(): physics_body.floor_max_angle = floor_max_angle).call_deferred()
					

				
## Sets a snapping distance. When set to a value different from 0.0, the body is kept attached to 
## slopes when calling move_and_slide(). The snapping vector is determined by the given distance 
## along the opposite direction of the up_direction. As long as the snapping vector is in contact 
## with the ground and the body moves against up_direction, the body will remain attached to the 
## surface. Snapping is not applied if the body moves along up_direction, meaning it contains 
## vertical rising velocity, so it will be able to detach from the ground when jumping or when the 
## body is pushed up by something. If you want to apply a snap without taking into account the 
## velocity, use apply_floor_snap().
@export_custom(PROPERTY_HINT_NONE, "suffix:m") 
var floor_snap_length: float = 3.5:
	set (value): # Ensure the physics_body is also updated if this value is set at runtime
			floor_snap_length = value
			if physics_body and is_instance_valid(physics_body):	
				# Defer a lambda function which updates the physics body. While this is not required doing so is safer
				(func(): physics_body.floor_snap_length = floor_snap_length).call_deferred()	

				
################################ Moving Platform Settings ######################
@export_group("Moving Platform")
## Collision layers that will be included for detecting floor bodies that will act as moving 
## platforms to be followed by the CharacterBody3D. By default, all floor bodies are detected and 
## propagate their velocity.
@export_flags_3d_physics 
var floor_layers: int = -1:
	set (value): # Ensure the physics_body is also updated if this value is set at runtime
		floor_layers = value
		if physics_body and is_instance_valid(physics_body):
			# Defer a lambda function which updates the physics body. While this is not required doing so is safer
			(func(): physics_body.floor_layers = floor_layers).call_deferred()	
			
## Collision layers that will be included for detecting wall bodies that will act as moving platforms
## to be followed by the CharacterBody3D. By default, all wall bodies are ignored.		
@export_flags_3d_physics 
var wall_layers: int = 0:
	set (value): # Ensure the physics_body is also updated if this value is set at runtime
		wall_layers = value
		if physics_body and is_instance_valid(physics_body):			
			# Defer a lambda function which updates the physics body. While this is not required doing so is safer
			(func(): physics_body.wall_layers = wall_layers).call_deferred()	

################################ Collision Shape 3D Settings ################################
## Extracted variables from the collision shape (capsule) that the Character Body requires
@export_category("CollisionShape3D")

## Radius of the player's collision capsule
@export_custom(PROPERTY_HINT_NONE, "suffix:m") 
var capsule_radius: float = 0.3:
	set (value): # Ensure the physics_body is also updated if this value is set at runtime
		capsule_radius = value
		if collision_shape and is_instance_valid(collision_shape):
			# Defer our update. While this is not required doing so is safer
			call_deferred("_update_capsule", capsule_radius, capsule_height)

## Height of the player's collision capsule
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var capsule_height: float = 1.8:  
	set (value): # Ensure the physics_body is also updated if this value is set at runtime
		capsule_height = value
		if collision_shape and is_instance_valid(collision_shape):
			# Defer our update. While this is not required doing so is safer
			call_deferred("_update_capsule", capsule_radius, capsule_height)

################################ Collision Settings ############################
@export_group("Collision")

## The physics layers this CollisionObject3D scans. Collision objects can scan one or more of 32 different 
## layers. See also collision_layer. Note: Object A can detect a contact with object B only if object 
## B is in any of the layers that object A scans. See Collision layers and masks in the documentation 
## for more information.
@export_flags_3d_physics 
var collision_layer: int = 2:
	set (value): # Ensure the physics_body is also updated if this value is set at runtime
		collision_layer = value
		if physics_body and is_instance_valid(physics_body):
			# Defer a lambda function which updates the physics body. While this is not required doing so is safer
			(func(): physics_body.collision_layer = collision_layer).call_deferred()	
			
## The physics layers this CollisionObject3D scans. Collision objects can scan one or more of 32 different 
## layers. See also collision_layer. Note: Object A can detect a contact with object B only if object 
## B is in any of the layers that object A scans. See Collision layers and masks in the documentation 
## for more information.
@export_flags_3d_physics 
var collision_mask: int = 1:
	set (value):  # Ensure the physics_body is also updated if this value is set at runtime
		collision_mask = value
		if physics_body and is_instance_valid(physics_body):
			# Defer a lambda function which updates the physics body. While this is not required doing so is safer
			(func(): physics_body.collision_mask = collision_mask).call_deferred()	

## The priority used to solve colliding when occurring penetration. The higher the priority is, 
## the lower the penetration into the object will be. This can for example be used to prevent the 
## player from breaking through the boundaries of a level.	
@export 
var collision_priority: float = 1:
	set (value):  # Ensure the physics_body is also updated if this value is set at runtime
		collision_priority = value
		if physics_body and is_instance_valid(physics_body):
			# Defer a lambda function which updates the physics body. While this is not required doing so is safer
			(func(): physics_body.priority = collision_priority).call_deferred()	
			
################################ VR Node Paths #################################
@export_group("VR Node Paths")

## Your left hand
@export_node_path("XRController3D") 
var left_controller_path: NodePath = "../LeftController"

## Your Right Hand
@export_node_path("XRController3D") 
var right_controller_path: NodePath = "../RightController" 

## Your HMD/Camera
@export_node_path("XRCamera3D") 
var camera_path: NodePath = "../XRCamera3D"

################################ General Debugging Settings ####################
## General debugging help
@export_category("Debug")

## Whether to show the capsule mesh (for debugging)
@export 
var show_capsule: bool = true  

## Color of the capsule (red by default)
@export 
var capsule_color: Color = Color(1.0, 0.0, 0.0, 0.8)  

## Enable detailed debug logging
@export 
var show_debug_logs: bool = false 

# Internal nodes
var physics_body: CharacterBody3D
var collision_shape: CollisionShape3D
var capsule_mesh: MeshInstance3D

# Node references
var xr_origin: XROrigin3D
var xr_camera: XRCamera3D
var left_controller: XRController3D
var right_controller: XRController3D

# Movement state
var vertical_velocity: float = 0.0
var move_dir: Vector3 = Vector3.ZERO
var is_sprinting: bool = false
var left_thumbstick_pressed: bool = false
var initialized: bool = false
var has_done_initial_setup: bool = false

# Variables for snap turning cooldown
var can_snap_turn: bool = true
var snap_timer: float = 0.0

# Direction vectors: Used to move CharacterBody3D (PhysicsBody) along the same forward/right direction as the HMD
var forward_direction: Vector3 = Vector3.FORWARD
var right_direction: Vector3 = Vector3.RIGHT
# Fail safe direction if forward_direction is invalid (i.e., user is looking straight up or straight down)
var previous_forward_direction: Vector3 = Vector3.FORWARD 
# Fail safe direction if right_direction is invalid (i.e., user is looking straight up or straight down)
var previous_right_direction: Vector3 = Vector3.RIGHT

# Debug variables
var debug_timer: float = 0.0

# Show/Hide variables based on other variables
func _validate_property(property: Dictionary) -> void:
	if (property.name == "toggle_sprint_mode" or property.name == "sprint_multiplier") and not allow_sprinting:
		property.usage |= PROPERTY_USAGE_READ_ONLY
	elif property.name == "jump_strength" and not allow_jumping:
		property.usage |= PROPERTY_USAGE_READ_ONLY
	elif property.name == "smooth_turn_speed" and not use_smooth_turning:
		property.usage |= PROPERTY_USAGE_READ_ONLY
		

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	
	# Check if we're attached to an XROrigin3D
	if not get_parent() is XROrigin3D:
		warnings.append("VRPhysicsLocomotion should be a child of an XROrigin3D node.")
	
	# Check if controller paths are valid
	if left_controller_path.is_empty() or not get_node_or_null(left_controller_path):
		warnings.append("Left controller path is invalid or empty.")
	
	if right_controller_path.is_empty() or not get_node_or_null(right_controller_path):
		warnings.append("Right controller path is invalid or empty.")
	
	if camera_path.is_empty() or not get_node_or_null(camera_path):
		warnings.append("Camera path is invalid or empty.")
		
	return warnings


func _ready():
	if Engine.is_editor_hint():
		return
	
	# Wait until the next frame to initialize
	# This gives time for the scene to be fully loaded which is important for HMD
	# initialization amongst other things
	call_deferred("_initialize")


func _initialize():
	# Get node references
	if not is_inside_tree():
		return
		
	xr_origin = get_parent() as XROrigin3D
	
	if not xr_origin:
		push_error("VRPhysicsLocomotion must be a child of an XROrigin3D node")
		return
	
	if not is_instance_valid(get_node_or_null(camera_path)):
		push_error("Camera path is invalid")
		return
		
	if not is_instance_valid(get_node_or_null(left_controller_path)):
		push_error("Left controller path is invalid")
		return
		
	if not is_instance_valid(get_node_or_null(right_controller_path)):
		push_error("Right controller path is invalid")
		return
	
	xr_camera = get_node(camera_path) as XRCamera3D
	left_controller = get_node(left_controller_path) as XRController3D
	right_controller = get_node(right_controller_path) as XRController3D
	
	# Create physics body
	call_deferred("_create_physics_body")
	
	# Initialize controller input
	if left_controller and right_controller:
		left_controller.button_pressed.connect(_on_controller_button_pressed.bind(left_controller))
		right_controller.button_pressed.connect(_on_controller_button_pressed.bind(right_controller))
		left_controller.button_released.connect(_on_controller_button_released.bind(left_controller))
		right_controller.button_released.connect(_on_controller_button_released.bind(right_controller))
		left_controller.input_vector2_changed.connect(_on_controller_input_vector2_changed.bind(left_controller))
		right_controller.input_vector2_changed.connect(_on_controller_input_vector2_changed.bind(right_controller))
	
	initialized = true
	if OS.is_debug_build():
		if show_debug_logs:
			print("VR Physics Locomotion initialized successfully")


func _exit_tree():
	# Clean up the physics body when the node is removed
	if physics_body and is_instance_valid(physics_body):
		physics_body.queue_free()


func _create_physics_body():
	if OS.is_debug_build():
		if show_debug_logs:
			print("Creating physics body...")
	
	# Create a CharacterBody3D for physics and bring over export settings. Note: If you need more
	# CharacterBody3D or CollisionShape3D settings modified from the editor inspector, copy and paste
	# the format used below, remembering to mark your new variables with @export like these were
	physics_body = CharacterBody3D.new()
	physics_body.name = "PhysicsBody"
	physics_body.collision_layer = collision_layer  # Player layer
	physics_body.collision_mask = collision_mask   # Environment layer
	physics_body.collision_priority = collision_priority # Match priority
	physics_body.floor_max_angle = floor_max_angle  # Maximum slope angle
	physics_body.floor_snap_length = floor_snap_length  # Better stair snapping
	physics_body.platform_floor_layers = floor_layers # What we consider the floor: Used in movement calculations
	physics_body.platform_wall_layers = wall_layers # What we consider walls: Used in movement calculations
	
	# Add collision shape
	collision_shape = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = capsule_radius
	capsule.height = capsule_height
	collision_shape.shape = capsule
	
	# Position the collision shape
	collision_shape.position = Vector3(0, capsule_height/2, 0)
	
	physics_body.add_child(collision_shape)
	
	# Add visual mesh if enabled
	if show_capsule:
		capsule_mesh = MeshInstance3D.new()
		var mesh: CapsuleMesh = CapsuleMesh.new()
		mesh.radius = capsule_radius
		mesh.height = capsule_height
		capsule_mesh.mesh = mesh
		
		# Make it visible with strong color
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = capsule_color
		capsule_mesh.material_override = material
		
		# Position the mesh at the same place as the collision shape
		capsule_mesh.position = collision_shape.position
		
		physics_body.add_child(capsule_mesh)
		
		if OS.is_debug_build():
			if show_debug_logs:
				print("Added capsule mesh with color: ", capsule_color)
	
	# Add to scene at the same level as the XROrigin - having them as 'siblings' in the tree
	# makes moving both the origin and the physics body easier as they don't implicity effect each other
	var parent_node: Node = xr_origin.get_parent()
	if OS.is_debug_build():
		if show_debug_logs:
			print("Adding physics body to: ", parent_node.name)
		
	parent_node.add_child(physics_body)
	if OS.is_debug_build():
		if show_debug_logs:
			print("Physics body added, in tree: ", physics_body.is_inside_tree())
	
	# Position capsule and initialize camera tracking
	if xr_origin and is_instance_valid(xr_origin) and xr_camera and is_instance_valid(xr_camera):
		has_done_initial_setup = true
		
		if OS.is_debug_build():
			if show_debug_logs:
				print("=== PHYSICS BODY INITIALIZATION ===")
				print("XROrigin global position: ", xr_origin.global_position)
				print("XROrigin rotation: ", xr_origin.rotation)
				print("XRCamera global position: ", xr_camera.global_position)
				print("XRCamera local position (transform.origin): ", xr_camera.position)
		
		# Get xr_camera's world space offset from xr_origin and use that to initialize 
		# the location of the physics body. This is equalivent to doing: 
		# xr_camera.global_position - xr_origin.global_position but is more explicit 
		# and does not require xr_camera to be a child of xr_origin (though it should be)
		var camera_offset_world: Vector3 = xr_origin.global_transform.basis * xr_camera.transform.origin

		if OS.is_debug_build():
			if show_debug_logs:
				print("XR Camera: ", xr_camera.global_position)
				print("Camera Offset World: ", camera_offset_world)
				print("XR Origin: ", xr_origin.global_position)
			
		# Position capsule at HMD horizontal position using the camera world offset
		var target_x: float = xr_origin.global_position.x + camera_offset_world.x
		var target_y: float = xr_origin.global_position.y - (capsule_height / 2.0) + 0.1
		var target_z: float = xr_origin.global_position.z + camera_offset_world.z

		physics_body.global_position = Vector3(target_x, target_y, target_z)
		physics_body.global_rotation = xr_origin.global_rotation
		
		if OS.is_debug_build():
			if show_debug_logs:
				print("Final physics body position: ", physics_body.global_position)
				print("=====================================")


func _process(delta: float):
	if Engine.is_editor_hint() or not initialized:
		return
		
	# Handle snap turn cooldown (if snap_turn_cooldown is <= 0, then we use the controller deadzone to reset snap turning
	if not can_snap_turn and snap_turn_cooldown > 0:
		snap_timer += delta
		if snap_timer >= snap_turn_cooldown: 
			can_snap_turn = true
			snap_timer = 0.0
	
	if xr_camera and is_instance_valid(xr_camera) and xr_camera.is_inside_tree():
		# Ensure physics forward/right direction vectors always match that of HMD forward/right direction vectors
		update_direction_vectors() 
	
	# Handle rotation with right thumbstick
	if right_controller and is_instance_valid(right_controller) and right_controller.is_inside_tree():
		var right_thumbstick: Vector2 = Vector2.ZERO
		if right_controller.is_button_pressed("primary"):
			right_thumbstick = right_controller.get_vector2("primary")
		
		# Apply deadzone
		if abs(right_thumbstick.x) < deadzone:
			right_thumbstick.x = 0
			# If we want to use deadzone to determine if we can snap turn 
			if snap_turn_cooldown <= 0: 
				can_snap_turn = true
				snap_timer = 0.0
		
		if right_thumbstick.x != 0:
			if use_smooth_turning:
				# Smooth turning (corrected direction)
				var rotation_amount: float = -right_thumbstick.x * smooth_turn_speed * delta
				rotate_player(rotation_amount)
			else:
				# Snap turning (corrected direction)
				if can_snap_turn:
					var direction: float = -sign(right_thumbstick.x)
					rotate_player(snap_turn_amount * direction)
					can_snap_turn = false
	
	# Handle sprint in hold mode
	if allow_sprinting and not toggle_sprint_mode:
		# In hold mode, sprint state directly matches thumbstick press state
		is_sprinting = left_thumbstick_pressed
	
	# Debug output every 2 seconds
	if OS.is_debug_build():
		if show_debug_logs:
			debug_timer += delta
			if debug_timer >= 2.0 and physics_body and is_instance_valid(physics_body):
				debug_timer = 0.0
				print("Physics body Y position: ", physics_body.global_position.y)
				print("On floor: ", physics_body.is_on_floor())
				print("Vertical velocity: ", vertical_velocity)
				print("Sprinting: ", is_sprinting, " (", "Toggle Mode" if toggle_sprint_mode else "Hold Mode", ")")
				print("Capsule visible: ", show_capsule and is_instance_valid(capsule_mesh))


func _physics_process(delta: float):
	if Engine.is_editor_hint() or not initialized:
		return
		
	if not physics_body or not is_instance_valid(physics_body) or not physics_body.is_inside_tree():
		return
		
	if not xr_origin or not is_instance_valid(xr_origin) or not xr_origin.is_inside_tree():
		return
	
	if not left_controller or not is_instance_valid(left_controller) or not left_controller.is_inside_tree():
		return
		
	if not xr_camera or not is_instance_valid(xr_camera) or not xr_camera.is_inside_tree():
		return
	
	# One-time setup to record initial camera position
	if not has_done_initial_setup:
		if OS.is_debug_build():
			if show_debug_logs:
				print("WARNING: Physics process capturing initial_camera_local_pos (should have been done in _create_physics_body)")
		
		has_done_initial_setup = true
	
	# Debug first frame position update
	if OS.is_debug_build():
		if show_debug_logs:
			var frame_count: int = Engine.get_physics_frames()
			if frame_count < 5:  # Log first few frames
				print("=== PHYSICS PROCESS FRAME ", frame_count, " ===")
				print("XROrigin global position: ", xr_origin.global_position)
				print("XRCamera local pos: ", xr_camera.position)
				print("XRCamera global pos: ", xr_camera.global_position)
				print("Physics body position: ", physics_body.global_position)
				var horizontal_distance: float = Vector2(
					xr_camera.global_position.x - physics_body.global_position.x,
					xr_camera.global_position.z - physics_body.global_position.z
				).length()
				print("Horizontal distance HMD to capsule: ", horizontal_distance, " meters")
	
	# ---- HANDLE THUMBSTICK MOVEMENT ----
	# Reset movement direction for thumbstick-based movement
	move_dir = Vector3.ZERO
	
	# Get the left thumbstick input for movement
	var left_thumbstick: Vector2 = Vector2.ZERO
	if left_controller.is_button_pressed("primary"):
		left_thumbstick = left_controller.get_vector2("primary")
	
	# Apply deadzone
	if left_thumbstick.length() < deadzone:
		left_thumbstick = Vector2.ZERO
	
	# Calculate movement direction based on camera orientation
	if left_thumbstick != Vector2.ZERO:
		move_dir += forward_direction * left_thumbstick.y
		move_dir += right_direction * left_thumbstick.x
		
		# Normalize to prevent diagonal movement from being faster
		if move_dir.length() > 1.0:
			move_dir = move_dir.normalized()
		
	# ---- APPLY PHYSICS ----
	
	# Apply gravity
	if not physics_body.is_on_floor():
		vertical_velocity -= gravity * delta
	else:
		vertical_velocity = -0.1  # Small downward force to keep grounded
	
	# Apply sprint multiplier if sprinting
	var current_speed: float = speed
	if allow_sprinting and is_sprinting:
		current_speed *= sprint_multiplier
		
	# Set velocity from physical (roomscale) movement
	var physics_body_to_camera: Vector3 = xr_camera.global_position - physics_body.global_position

	# When moving an object via velocity, delta is taken into account. Therefore, if we want to move
	# the physics_body the entire length of the physics_body_to_camera, we divide by delta to undo 
	# the future multiply
	physics_body.velocity = physics_body_to_camera / delta
	
	# Add velocity from thumbstick movement
	physics_body.velocity += move_dir * current_speed
	physics_body.velocity.y = vertical_velocity
	
	# Apply movement using CharacterBody3D physics
	physics_body.move_and_slide()
	
	# ---- UPDATE XRORIGIN POSITION ----
	# After physics is applied, we need to move the XROrigin to follow the physics body's movement.
	# But we need to maintain the correct offset relationship (which could have changed this tick if 
	# the player physically moved in their play space). Therefore, we get the xr_camera's offset
	# from xr_origin in the same transform space as xr_origin. This takes into consideration
	# the origin's rotation and scale and is more explicit than doing 
	# camera_offset_world = xr_camera.global_position - xr_origin.global_position though the result,
	# since xr_camera is a direct child of xr_origin, would be the same. We could also use:
	# var rotated_movement = xr_camera.position.rotated(Vector3.UP, xr_origin.rotation.y)
	# xr_origin.global_position = physics_body.global_position - rotated_movement
	# but that method does not take into consideration Y movement (which we throw out anyways) and scale
	# (which should be 1 on xr_origin and 1 on xr_camera). Computationally speaking, the method chosen
	# below is the essentially the same cost as the above options but is more explicit on what it is doing
	# and not restricted by correct parenting and scale
	
	# Calculate the offset between the camera and the origin in the same transform space 
	var camera_offset_world: Vector3 = xr_origin.global_transform.basis * xr_camera.position
	
	# Apply the difference between the offset and the physics_body to the origin so the origin follows the physics body's movement
	xr_origin.global_position = physics_body.global_position - Vector3(camera_offset_world.x, 0.0, camera_offset_world.z)
	
	
	# Ensure the Y position of the XROrigin maintains the correct height
	# Old manual method
	#xr_origin.global_position.y = (physics_body.global_position.y - capsule_height/2) + hmd_height
	# Offset Method
	xr_origin.global_position.y = physics_body.global_position.y + hmd_height_offset


func update_direction_vectors():
	if not xr_camera or not is_instance_valid(xr_camera) or not xr_camera.is_inside_tree():
		return
		
	# Get the camera's forward and right directions, but remove vertical component
	var camera_transform: Transform3D = xr_camera.global_transform
	
	# Forward direction (z-axis) without vertical component
	forward_direction = -camera_transform.basis.z
	forward_direction.y = 0
	if forward_direction.length() > 0.001: # Ensure our vector is safe to normalize
		forward_direction = forward_direction.normalized()
		previous_forward_direction = forward_direction
	else:
		# Just a failsafe - you would to have to be looking straight up or straight down to trigger this
		# If it does happen, then use the last safe forward direction
		forward_direction = previous_forward_direction
	
	# Right direction (x-axis) without vertical component
	right_direction = camera_transform.basis.x
	right_direction.y = 0
	if right_direction.length() > 0.001: # Ensure our vector is safe to normalize
		right_direction = right_direction.normalized()
		previous_right_direction = right_direction
	else:
		# Just a failsafe - you would to have to be looking straight up or straight down to trigger this.
		# If it does happen, then use the last safe right direction
		right_direction = previous_right_direction


func rotate_player(radians: float):
	if not xr_origin or not is_instance_valid(xr_origin) or not xr_origin.is_inside_tree():
		return
		
	if not physics_body or not is_instance_valid(physics_body) or not physics_body.is_inside_tree():
		return
	
	# Simply rotate the XROrigin around its Y axis
	xr_origin.rotate_y(radians)
	
	# Update the physics body rotation to match
	physics_body.global_rotation.y = xr_origin.global_rotation.y
	
	# No position updates needed here - all positioning is now handled 
	# in _physics_process with the rotated local movement calculations


func jump():
	if physics_body and is_instance_valid(physics_body) and physics_body.is_on_floor() and allow_jumping:
		print("JUMPING! On floor:", physics_body.is_on_floor())
		vertical_velocity = jump_strength
		
		# Force immediate upward movement to ensure it happens
		physics_body.velocity.y = jump_strength
		physics_body.move_and_slide()
		
		print("Applied vertical velocity:", vertical_velocity)


func toggle_sprint():
	if allow_sprinting and toggle_sprint_mode:
		is_sprinting = !is_sprinting
		print("Sprint toggled: ", is_sprinting)


func _on_controller_button_pressed(button_name: String, controller: XRController3D):
	#Debug print controller input names 
	#print("Button pressed: ", button_name, " on controller: ", "left" if controller == left_controller else "right")
	# Handle jump
	if controller == right_controller and button_name == "ax_button" and allow_jumping:
		jump()
	
	# Handle sprint activation
	if controller == left_controller and button_name == "primary_click" and allow_sprinting:
		left_thumbstick_pressed = true
		
		if toggle_sprint_mode:
			toggle_sprint()
		else:
			# In hold mode, we'll set the sprint state in _process
			pass


func _on_controller_button_released(button_name: String, controller: XRController3D):
	# Handle sprint deactivation for hold mode
	if controller == left_controller and button_name == "primary_click":
		left_thumbstick_pressed = false
		# The actual sprint state will be updated in _process


func _on_controller_input_vector2_changed(button_name: String, vector: Vector2, controller: XRController3D):
	pass
	
	
## Helper function to update the capsule radius and height	
func _update_capsule(new_radius: float, new_height: float) -> void:
	if collision_shape and is_instance_valid(collision_shape):
		var shape: Shape3D = collision_shape.shape
		if shape and is_instance_valid(collision_shape) and shape is CapsuleShape3D:
			# Duplicate via deep copy to ensure we got anything and everything bound to this shape
			var local_shape: Shape3D = shape.duplicate(true)
			local_shape.radius = new_radius
			local_shape.height = new_height
			collision_shape.shape = local_shape
			if show_capsule:
				var mesh: CapsuleMesh = CapsuleMesh.new()
				mesh.radius = new_radius
				mesh.height = new_height
				capsule_mesh.mesh = mesh
