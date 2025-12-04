@tool
extends Node
class_name VRIKComponent

## A VR Inverse Kinematics component that tracks HMD and hand controllers
## to animate a skeletal mesh in VR. Attach this to an XROrigin3D.

# Skeletal mesh settings
@export var skeletal_mesh_scene: PackedScene:
	set(value):
		skeletal_mesh_scene = value
		if Engine.is_editor_hint():
			update_configuration_warnings()
		elif is_inside_tree():
			_load_skeletal_mesh()

@export var skeleton: Skeleton3D:
	set(value):
		skeleton = value
		if Engine.is_editor_hint():
			update_configuration_warnings()

# Tracking settings
@export_group("Tracking")
@export var track_head: bool = true
@export var track_hands: bool = true
@export var track_legs: bool = true  ## Enable leg IK for crouching/squatting based on HMD height
@export var smooth_tracking: bool = false  ## Enable smoothing to reduce jitter (adds slight lag)
@export var smoothing_speed: float = 15.0  ## Higher = snappier tracking (only used if smooth_tracking enabled)

# Body positioning
@export_group("Body Settings")
## Enable to parent skeleton to VRLocomotion physics capsule. When enabled, skeleton rotates with snap turns and moves with player locomotion. Disable for standalone use without VRLocomotion (e.g., seated VR).
@export var use_locomotion_integration: bool = true
@export var seated_mode: bool = false  ## Enable seated VR mode - offsets HMD/controller tracking up to match full-height skeleton while physically seated
@export var seated_height_offset: float = 0.5  ## Vertical offset added to HMD/hands in seated mode (distance from chair seat to where legs would be if standing)
@export var body_height_offset: float = 0.0  # Adjust body height relative to HMD
@export var body_forward_offset: float = 0.0  # Adjust body forward/backward position (positive = forward, negative = backward)
@export var align_skeleton_with_hmd: bool = true  # Automatically rotate skeleton to face HMD direction
@export var hmd_rotation_deadzone: float = 45.0  # Degrees of HMD rotation before body starts rotating (0 = always rotate, 180 = never rotate)
@export var body_rotation_smoothing: float = 5.0  # How smoothly the body rotates to follow HMD (higher = faster)
@export var standing_eye_height: float = 1.6  ## Reference standing eye height in meters (adjust for your height). HMD below this = crouched, at this = standing
@export var foot_height_offset: float = 0.0  ## Offset feet above/below ground (positive = higher, negative = lower)
@export var foot_spacing: float = 0.3  ## Distance between feet (meters)

@export_group("Hand Orientation (Euler XYZ)")
@export var hand_rotation_x: float = -90.0  # Roll (around forward axis)
@export var hand_rotation_y: float = 0.0    # Pitch (around right axis)
@export var hand_rotation_z: float = 0.0    # Yaw (around up axis)
@export_enum("XYZ", "XZY", "YXZ", "YZX", "ZXY", "ZYX") var hand_rotation_order: int = 0
@export var mirror_right_hand: bool = true  # Automatically mirror rotation for right hand

@export_subgroup("Hand Position Offset")
@export var hand_position_offset: Vector3 = Vector3(0, 0, 0)  # Offset from controller to hand (in controller's local space)
@export var mirror_right_hand_position: bool = true  # Automatically mirror X offset for right hand

@export_subgroup("Override Right Hand (if not mirroring)")
@export var override_right_hand: bool = false
@export var right_hand_rotation_x: float = -90.0
@export var right_hand_rotation_y: float = 0.0
@export var right_hand_rotation_z: float = 0.0
@export_enum("XYZ", "XZY", "YXZ", "YZX", "ZXY", "ZYX") var right_hand_rotation_order: int = 0
@export var right_hand_position_offset: Vector3 = Vector3(0, 0, 0)

@export_group("Head Orientation (Euler XYZ)")
@export var head_rotation_x: float = 0.0
@export var head_rotation_y: float = 180.0
@export var head_rotation_z: float = 0.0

# Bone name mappings - customize these based on your skeleton
@export_group("Bone Mappings")
@export var head_bone_name: String = "Head"
@export var neck_bone_name: String = "Neck"
@export var spine_bone_name: String = "Spine"
@export var left_shoulder_bone_name: String = "LeftShoulder"
@export var left_arm_bone_name: String = "LeftArm"
@export var left_forearm_bone_name: String = "LeftForeArm"
@export var left_hand_bone_name: String = "LeftHand"
@export var right_shoulder_bone_name: String = "RightShoulder"
@export var right_arm_bone_name: String = "RightArm"
@export var right_forearm_bone_name: String = "RightForeArm"
@export var right_hand_bone_name: String = "RightHand"
@export var hips_bone_name: String = "Hips"
@export var left_upleg_bone_name: String = "LeftUpLeg"
@export var left_leg_bone_name: String = "LeftLeg"
@export var left_foot_bone_name: String = "LeftFoot"
@export var right_upleg_bone_name: String = "RightUpLeg"
@export var right_leg_bone_name: String = "RightLeg"
@export var right_foot_bone_name: String = "RightFoot"

# Controller paths
@export_group("VR Node Paths")
@export_node_path("XRController3D") var left_controller_path: NodePath = "../LeftController"
@export_node_path("XRController3D") var right_controller_path: NodePath = "../RightController"
@export_node_path("XRCamera3D") var camera_path: NodePath = "../XRCamera3D"

# Debug settings
@export_category("Debug")
@export var show_debug_logs: bool = false  ## Enable detailed debug logging
@export var debug_on_button_press: bool = true  ## Only print debug info when right thumbstick clicked
@export var show_controller_axes: bool = false  ## Visualize controller coordinate axes
@export var toggle_seated_key: Key = KEY_T  ## Keyboard key to toggle seated mode at runtime (for testing)

# Internal references
var xr_origin: XROrigin3D
var xr_camera: XRCamera3D
var left_controller: XRController3D
var right_controller: XRController3D
var skeleton_instance: Node3D

# Bone indices (cached for performance)
var head_bone_idx: int = -1
var neck_bone_idx: int = -1
var spine_bone_idx: int = -1
var left_shoulder_bone_idx: int = -1
var left_arm_bone_idx: int = -1
var left_forearm_bone_idx: int = -1
var left_hand_bone_idx: int = -1
var right_shoulder_bone_idx: int = -1
var right_arm_bone_idx: int = -1
var right_forearm_bone_idx: int = -1
var right_hand_bone_idx: int = -1
var hips_bone_idx: int = -1
var left_upleg_bone_idx: int = -1
var left_leg_bone_idx: int = -1
var left_foot_bone_idx: int = -1
var right_upleg_bone_idx: int = -1
var right_leg_bone_idx: int = -1
var right_foot_bone_idx: int = -1

# SkeletonIK3D nodes for arm and leg IK
var left_arm_ik: SkeletonIK3D
var right_arm_ik: SkeletonIK3D
var left_leg_ik: SkeletonIK3D
var right_leg_ik: SkeletonIK3D

# IK targets for hands and feet
var left_hand_target: Node3D
var right_hand_target: Node3D
var left_foot_target: Node3D
var right_foot_target: Node3D

# Smooth tracking state
var smoothed_head_transform: Transform3D
var smoothed_left_hand_transform: Transform3D
var smoothed_right_hand_transform: Transform3D

# Body rotation tracking
var target_body_rotation_y: float = 0.0  # Target rotation for the body
var current_body_rotation_y: float = 0.0  # Current smoothed rotation
var last_physics_body_rotation_y: float = 0.0  # Track physics body rotation to detect snap turns

# HMD height tracking for leg IK
var initial_hmd_height: float = 0.0  # Calibrated HMD height at startup
var current_hmd_height_delta: float = 0.0  # How much HMD has moved up/down from initial

# Seated mode tracking
var seated_mode_active: bool = false  # Track if seated mode is currently active

# Initialization
var initialized: bool = false
var skeleton_needs_reparenting: bool = false
var ik_configured: bool = false  # Track if IK nodes are fully configured

# Debug visualization
var left_hand_axes: Node3D
var right_hand_axes: Node3D
var debug_button_pressed: bool = false

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = PackedStringArray()
	
	# Check if we're attached to an XROrigin3D
	if not get_parent() is XROrigin3D:
		warnings.append("VRIKComponent should be a child of an XROrigin3D node.")
	
	# Check if skeletal mesh scene is assigned
	if not skeletal_mesh_scene and not skeleton:
		warnings.append("No skeletal mesh scene or skeleton assigned. Please assign a skeletal mesh scene (recommended) or skeleton directly.")
	
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
	
	call_deferred("_initialize")

func _initialize():
	if not is_inside_tree():
		return
	
	# Get XR node references
	xr_origin = get_parent() as XROrigin3D
	if not xr_origin:
		push_error("VRIKComponent must be a child of XROrigin3D")
		return
	
	# Load skeletal mesh if scene is assigned
	if skeletal_mesh_scene and not skeleton:
		_load_skeletal_mesh()
	
	# Get controller and camera references
	xr_camera = get_node_or_null(camera_path) as XRCamera3D
	left_controller = get_node_or_null(left_controller_path) as XRController3D
	right_controller = get_node_or_null(right_controller_path) as XRController3D
	
	if not xr_camera:
		push_error("VRIKComponent: XRCamera3D not found at path: " + str(camera_path))
		return
	
	if not left_controller:
		push_warning("VRIKComponent: Left controller not found at path: " + str(left_controller_path))
	
	if not right_controller:
		push_warning("VRIKComponent: Right controller not found at path: " + str(right_controller_path))
	
	# Cache bone indices
	if skeleton:
		_cache_bone_indices()
	
	# Initialize smoothed transforms
	if xr_camera:
		smoothed_head_transform = xr_camera.global_transform
		if show_debug_logs:
			print("VRIKComponent: HMD height from floor: ", xr_camera.position.y, "m")
	if left_controller:
		smoothed_left_hand_transform = left_controller.global_transform
	if right_controller:
		smoothed_right_hand_transform = right_controller.global_transform
	
	# Setup debug visualization if enabled
	if show_controller_axes:
		_create_debug_axes()
	
	# Setup SkeletonIK3D for arms
	if skeleton:
		_setup_skeleton_ik()
	
	initialized = true
	
	if show_debug_logs:
		print("VRIKComponent initialized successfully")
		print("Tracking - Head: ", track_head, " | Hands: ", track_hands, " | Smooth: ", smooth_tracking)

func _cache_bone_indices():
	if not skeleton:
		return
	
	head_bone_idx = skeleton.find_bone(head_bone_name)
	neck_bone_idx = skeleton.find_bone(neck_bone_name)
	spine_bone_idx = skeleton.find_bone(spine_bone_name)
	left_shoulder_bone_idx = skeleton.find_bone(left_shoulder_bone_name)
	left_arm_bone_idx = skeleton.find_bone(left_arm_bone_name)
	left_forearm_bone_idx = skeleton.find_bone(left_forearm_bone_name)
	left_hand_bone_idx = skeleton.find_bone(left_hand_bone_name)
	right_shoulder_bone_idx = skeleton.find_bone(right_shoulder_bone_name)
	right_arm_bone_idx = skeleton.find_bone(right_arm_bone_name)
	right_forearm_bone_idx = skeleton.find_bone(right_forearm_bone_name)
	right_hand_bone_idx = skeleton.find_bone(right_hand_bone_name)
	hips_bone_idx = skeleton.find_bone(hips_bone_name)
	left_upleg_bone_idx = skeleton.find_bone(left_upleg_bone_name)
	left_leg_bone_idx = skeleton.find_bone(left_leg_bone_name)
	left_foot_bone_idx = skeleton.find_bone(left_foot_bone_name)
	right_upleg_bone_idx = skeleton.find_bone(right_upleg_bone_name)
	right_leg_bone_idx = skeleton.find_bone(right_leg_bone_name)
	right_foot_bone_idx = skeleton.find_bone(right_foot_bone_name)
	
	if show_debug_logs:
		print("=== VRIK Bone Mapping ===")
		print("  Head: ", head_bone_idx, " (", head_bone_name, ")")
		print("  Neck: ", neck_bone_idx, " (", neck_bone_name, ")")
		print("  Spine: ", spine_bone_idx, " (", spine_bone_name, ")")
		print("  Left Shoulder: ", left_shoulder_bone_idx, " (", left_shoulder_bone_name, ")")
		print("  Left Arm: ", left_arm_bone_idx, " (", left_arm_bone_name, ")")
		print("  Left Forearm: ", left_forearm_bone_idx, " (", left_forearm_bone_name, ")")
		print("  Left Hand: ", left_hand_bone_idx, " (", left_hand_bone_name, ")")
		print("  Right Shoulder: ", right_shoulder_bone_idx, " (", right_shoulder_bone_name, ")")
		print("  Right Arm: ", right_arm_bone_idx, " (", right_arm_bone_name, ")")
		print("  Right Forearm: ", right_forearm_bone_idx, " (", right_forearm_bone_name, ")")
		print("  Right Hand: ", right_hand_bone_idx, " (", right_hand_bone_name, ")")
		print("  Hips: ", hips_bone_idx, " (", hips_bone_name, ")")
		print("  Left UpLeg: ", left_upleg_bone_idx, " (", left_upleg_bone_name, ")")
		print("  Left Leg: ", left_leg_bone_idx, " (", left_leg_bone_name, ")")
		print("  Left Foot: ", left_foot_bone_idx, " (", left_foot_bone_name, ")")
		print("  Right UpLeg: ", right_upleg_bone_idx, " (", right_upleg_bone_name, ")")
		print("  Right Leg: ", right_leg_bone_idx, " (", right_leg_bone_name, ")")
		print("  Right Foot: ", right_foot_bone_idx, " (", right_foot_bone_name, ")")
		print("Bones with index -1 were not found and won't be tracked")
		print("========================")

func _setup_skeleton_ik():
	"""Create and configure SkeletonIK3D nodes for arm tracking"""
	if not skeleton:
		return
	
	# Create IK target nodes
	left_hand_target = Node3D.new()
	left_hand_target.name = "LeftHandIKTarget"
	add_child(left_hand_target)
	
	right_hand_target = Node3D.new()
	right_hand_target.name = "RightHandIKTarget"
	add_child(right_hand_target)
	
	# Setup left arm IK
	if left_arm_bone_idx >= 0 and left_hand_bone_idx >= 0:
		left_arm_ik = SkeletonIK3D.new()
		left_arm_ik.name = "LeftArmIK"
		
		# Configure BEFORE adding to skeleton to avoid build_chain() errors
		left_arm_ik.root_bone = skeleton.get_bone_name(left_arm_bone_idx)
		left_arm_ik.tip_bone = skeleton.get_bone_name(left_hand_bone_idx)
		
		# Now add to skeleton (this will trigger build_chain())
		skeleton.add_child(left_arm_ik)
		
		# Finish configuration after being added to tree
		call_deferred("_finalize_arm_ik", left_arm_ik, "Left")
	
	# Setup right arm IK
	if right_arm_bone_idx >= 0 and right_hand_bone_idx >= 0:
		right_arm_ik = SkeletonIK3D.new()
		right_arm_ik.name = "RightArmIK"
		
		# Configure BEFORE adding to skeleton to avoid build_chain() errors
		right_arm_ik.root_bone = skeleton.get_bone_name(right_arm_bone_idx)
		right_arm_ik.tip_bone = skeleton.get_bone_name(right_hand_bone_idx)
		
		# Now add to skeleton (this will trigger build_chain())
		skeleton.add_child(right_arm_ik)
		
		# Finish configuration after being added to tree
		call_deferred("_finalize_arm_ik", right_arm_ik, "Right")
	
	# Create foot IK target nodes
	left_foot_target = Node3D.new()
	left_foot_target.name = "LeftFootIKTarget"
	add_child(left_foot_target)
	
	right_foot_target = Node3D.new()
	right_foot_target.name = "RightFootIKTarget"
	add_child(right_foot_target)
	
	# Setup left leg IK
	if left_upleg_bone_idx >= 0 and left_foot_bone_idx >= 0:
		left_leg_ik = SkeletonIK3D.new()
		left_leg_ik.name = "LeftLegIK"
		
		# Configure BEFORE adding to skeleton to avoid build_chain() errors
		left_leg_ik.root_bone = skeleton.get_bone_name(left_upleg_bone_idx)
		left_leg_ik.tip_bone = skeleton.get_bone_name(left_foot_bone_idx)
		
		# Now add to skeleton (this will trigger build_chain())
		skeleton.add_child(left_leg_ik)
		
		# Finish configuration after being added to tree
		call_deferred("_finalize_leg_ik", left_leg_ik, "Left")
	
	# Setup right leg IK
	if right_upleg_bone_idx >= 0 and right_foot_bone_idx >= 0:
		right_leg_ik = SkeletonIK3D.new()
		right_leg_ik.name = "RightLegIK"
		
		# Configure BEFORE adding to skeleton to avoid build_chain() errors
		right_leg_ik.root_bone = skeleton.get_bone_name(right_upleg_bone_idx)
		right_leg_ik.tip_bone = skeleton.get_bone_name(right_foot_bone_idx)
		
		# Now add to skeleton (this will trigger build_chain())
		skeleton.add_child(right_leg_ik)
		
		# Finish configuration after being added to tree
		call_deferred("_finalize_leg_ik", right_leg_ik, "Right")

func _finalize_arm_ik(ik_node: SkeletonIK3D, side: String):
	"""Finalize arm IK configuration after it's been added to the scene tree"""
	if not ik_node or not skeleton:
		return
	
	# Set target node path
	if side == "Left":
		ik_node.target_node = ik_node.get_path_to(left_hand_target)
	else:
		ik_node.target_node = ik_node.get_path_to(right_hand_target)
	
	# Set additional IK parameters
	ik_node.use_magnet = true
	ik_node.magnet = Vector3(0, -1, 0)  # Pull elbow downward
	ik_node.min_distance = 0.01
	ik_node.max_iterations = 100
	ik_node.interpolation = 1.0
	
	if show_debug_logs:
		print(side, " arm IK finalized: ", ik_node.root_bone, " -> ", ik_node.tip_bone)
	
	# Check if both arm IKs are now configured
	if left_arm_ik and right_arm_ik:
		if left_arm_ik.root_bone != "" and right_arm_ik.root_bone != "":
			ik_configured = true
			if show_debug_logs:
				print("Both arm IKs are now configured and ready")

func _finalize_leg_ik(ik_node: SkeletonIK3D, side: String):
	"""Finalize leg IK configuration after it's been added to the scene tree"""
	if not ik_node or not skeleton:
		return
	
	# Set target node path
	if side == "Left":
		ik_node.target_node = ik_node.get_path_to(left_foot_target)
	else:
		ik_node.target_node = ik_node.get_path_to(right_foot_target)
	
	# Set additional IK parameters
	ik_node.use_magnet = true
	ik_node.magnet = Vector3(0, 0, 1)  # Pull knee forward (in local space)
	ik_node.min_distance = 0.01
	ik_node.max_iterations = 100
	ik_node.interpolation = 1.0
	ik_node.override_tip_basis = false  # Don't let IK rotate the foot bone
	
	if show_debug_logs:
		print(side, " leg IK finalized: ", ik_node.root_bone, " -> ", ik_node.tip_bone)

func _process(delta: float):
	if Engine.is_editor_hint() or not initialized or not skeleton:
		return
	
	# Try to reparent skeleton to physics body if needed
	if skeleton_needs_reparenting:
		_try_reparent_to_physics_body()
	
	# Toggle seated mode with keyboard key (for testing)
	if Input.is_key_pressed(toggle_seated_key):
		if not get_meta("_seated_toggle_pressed", false):
			seated_mode = !seated_mode
			print("VRIKComponent: Seated mode ", "ENABLED" if seated_mode else "DISABLED")
			_update_seated_mode()
			set_meta("_seated_toggle_pressed", true)
	else:
		set_meta("_seated_toggle_pressed", false)
	
	# Check for debug button press (Y button on right controller = by_button)
	if debug_on_button_press and right_controller:
		debug_button_pressed = right_controller.is_button_pressed("by_button")
	else:
		debug_button_pressed = false
	
	# Update smoothed transforms
	if smooth_tracking:
		_update_smoothed_transforms(delta)
	
	# Update skeleton bones based on VR tracking
	if track_head:
		_update_head_tracking()
	
	if track_hands:
		_update_hand_tracking()
	
	if track_legs:
		_update_leg_tracking()
	
	# Update body positioning
	_update_body_position()
	
	# Update debug visualization
	if show_controller_axes:
		_update_debug_axes()

func _update_smoothed_transforms(delta: float):
	var interp_speed = smoothing_speed * delta
	
	if xr_camera:
		smoothed_head_transform = smoothed_head_transform.interpolate_with(
			xr_camera.global_transform, 
			interp_speed
		)
	
	if left_controller:
		smoothed_left_hand_transform = smoothed_left_hand_transform.interpolate_with(
			left_controller.global_transform,
			interp_speed
		)
	
	if right_controller:
		smoothed_right_hand_transform = smoothed_right_hand_transform.interpolate_with(
			right_controller.global_transform,
			interp_speed
		)

func _update_head_tracking():
	if not xr_camera or head_bone_idx < 0:
		return
	
	# Get the transform to use (smoothed or direct)
	# Note: v_offset is already applied to camera's transform by XRCamera3D
	var head_transform = smoothed_head_transform if smooth_tracking else xr_camera.global_transform
	
	# Apply head rotation offset using individual axes
	var offset_basis = Basis.from_euler(Vector3(head_rotation_x, head_rotation_y, head_rotation_z) * PI / 180.0)
	head_transform.basis = head_transform.basis * offset_basis
	
	# Convert to skeleton local space
	var skeleton_global_inv = skeleton.global_transform.affine_inverse()
	var local_head_transform = skeleton_global_inv * head_transform
	
	# Get the rest pose for reference
	var head_rest = skeleton.get_bone_rest(head_bone_idx)
	
	# Apply rotation to head bone
	if head_bone_idx >= 0:
		# Get parent bone transform if neck exists
		var parent_global_transform = Transform3D.IDENTITY
		if neck_bone_idx >= 0:
			parent_global_transform = skeleton.get_bone_global_pose(neck_bone_idx)
		
		# Calculate relative rotation for the head
		var head_pose = parent_global_transform.affine_inverse() * local_head_transform
		
		# Apply rotation relative to rest pose
		var final_rotation = head_rest.basis.get_rotation_quaternion() * head_pose.basis.get_rotation_quaternion()
		skeleton.set_bone_pose_rotation(head_bone_idx, final_rotation)

func _update_hand_tracking():
	# Use SkeletonIK3D for hand tracking
	if not ik_configured:
		return  # Wait for IK to be fully configured
	
	if left_controller and left_arm_ik:
		var target_transform = smoothed_left_hand_transform if smooth_tracking else left_controller.global_transform
		
		# Apply hand position offset in controller's local space
		var position_offset = hand_position_offset
		target_transform.origin += target_transform.basis * position_offset
		
		# Apply hand rotation offset
		var left_rotation = Vector3(hand_rotation_x, hand_rotation_y, hand_rotation_z)
		var rotation_offset = _get_rotation_from_euler(left_rotation, hand_rotation_order, false)
		
		left_hand_target.global_transform = target_transform
		left_hand_target.transform.basis = left_hand_target.transform.basis * rotation_offset
		left_arm_ik.start()
	
	if right_controller and right_arm_ik:
		var target_transform = smoothed_right_hand_transform if smooth_tracking else right_controller.global_transform
		
		# Apply hand position offset (with mirroring if enabled)
		var position_offset: Vector3
		if override_right_hand:
			position_offset = right_hand_position_offset
		else:
			position_offset = hand_position_offset
			if mirror_right_hand_position:
				position_offset.x = -position_offset.x  # Mirror X axis
		
		target_transform.origin += target_transform.basis * position_offset
		
		# Apply hand rotation offset (with mirroring if enabled)
		var right_rotation: Vector3
		var right_order: int
		var should_mirror: bool
		
		if override_right_hand:
			right_rotation = Vector3(right_hand_rotation_x, right_hand_rotation_y, right_hand_rotation_z)
			right_order = right_hand_rotation_order
			should_mirror = false
		else:
			right_rotation = Vector3(hand_rotation_x, hand_rotation_y, hand_rotation_z)
			right_order = hand_rotation_order
			should_mirror = mirror_right_hand
		
		var rotation_offset = _get_rotation_from_euler(right_rotation, right_order, should_mirror)
		
		right_hand_target.global_transform = target_transform
		right_hand_target.transform.basis = right_hand_target.transform.basis * rotation_offset
		right_arm_ik.start()

func _update_leg_tracking():
	"""Update leg IK to keep feet grounded while allowing crouching"""
	if not left_leg_ik or not right_leg_ik or not xr_camera or not skeleton_instance:
		return
	
	# Get current HMD height from floor (absolute position with floor-based tracking)
	# Note: world_scale automatically scales all tracking positions
	var current_hmd_height = xr_camera.global_position.y - xr_origin.global_position.y
	
	# When in seated mode, add back the offset since we artificially raised the origin
	if seated_mode_active:
		current_hmd_height += seated_height_offset
	
	# Calculate height delta from standing reference height
	current_hmd_height_delta = current_hmd_height - standing_eye_height
	
	# Always clamp so hips can only go DOWN (crouch), never UP
	current_hmd_height_delta = min(current_hmd_height_delta, 0.0)
	
	# Adjust hip bone height based on HMD height relative to standing
	# When HMD is below standing height, hips move down (crouch)
	# When HMD is at standing height, hips at rest pose (clamped to 0)
	if hips_bone_idx >= 0:
		var hip_rest_pose = skeleton.get_bone_rest(hips_bone_idx)
		var hip_pose = skeleton.get_bone_pose(hips_bone_idx)
		
		# Adjust hip position based on how far HMD is from standing reference
		var adjusted_position = hip_rest_pose.origin
		adjusted_position.y += current_hmd_height_delta
		
		hip_pose.origin = adjusted_position
		skeleton.set_bone_pose_position(hips_bone_idx, hip_pose.origin)
	
	# Position foot targets at the ground level (capsule base or XROrigin base)
	# Use physics body position if using locomotion integration, otherwise use XROrigin
	var physics_body = _find_physics_body() if use_locomotion_integration else null
	var ground_reference: Vector3
	if physics_body:
		# Use physics capsule base as ground reference
		ground_reference = physics_body.global_position
	else:
		# Use XROrigin base as ground reference
		ground_reference = xr_origin.global_position
	
	# Get the skeleton's forward direction for proper foot placement
	var skeleton_forward = -skeleton_instance.global_transform.basis.z
	skeleton_forward.y = 0
	if skeleton_forward.length() > 0.001:
		skeleton_forward = skeleton_forward.normalized()
	else:
		skeleton_forward = Vector3.FORWARD
	
	var skeleton_right = skeleton_instance.global_transform.basis.x
	skeleton_right.y = 0
	skeleton_right = skeleton_right.normalized()
	
	# Apply body forward offset to match skeleton position
	var foot_base_position = ground_reference + (skeleton_forward * body_forward_offset)
	
	# Set foot target rotations to match skeleton rotation (so they rotate with snap turns)
	var skeleton_rotation_y = skeleton_instance.global_rotation.y
	
	# Left foot target - positioned to the left at ground level
	# Use positive spacing with skeleton_right to place left foot to character's LEFT
	left_foot_target.global_position = foot_base_position + (skeleton_right * foot_spacing / 2.0)
	left_foot_target.global_position.y = ground_reference.y + foot_height_offset
	left_foot_target.rotation.y = skeleton_rotation_y
	
	# Right foot target - positioned to the right at ground level
	# Use negative spacing to place right foot to character's RIGHT
	right_foot_target.global_position = foot_base_position + (skeleton_right * -foot_spacing / 2.0)
	right_foot_target.global_position.y = ground_reference.y + foot_height_offset
	right_foot_target.rotation.y = skeleton_rotation_y
	
	# Solve leg IK to bend knees and keep feet planted
	left_leg_ik.start()
	right_leg_ik.start()

func _update_body_position():
	if not skeleton_instance or not xr_camera:
		return
	
	# Check if skeleton is parented to physics body or XROrigin
	var physics_body = _find_physics_body()
	var is_parented_to_capsule = (skeleton_instance.get_parent() == physics_body)
	
	if is_parented_to_capsule and physics_body:
		# Skeleton is child of physics body - use local positioning
		# The skeleton moves and rotates with the capsule automatically
		
		# Set local position relative to capsule
		var local_pos = Vector3.ZERO
		local_pos.y = body_height_offset
		
		# Apply forward offset in the skeleton's local forward direction
		# Get the skeleton's forward direction after rotation (local -Z axis)
		if abs(body_forward_offset) > 0.001:
			var skeleton_local_forward = -skeleton_instance.transform.basis.z
			local_pos += skeleton_local_forward * body_forward_offset
		
		skeleton_instance.position = local_pos
		
		# Optionally update rotation to follow HMD yaw (relative to capsule)
		if align_skeleton_with_hmd:
			# Detect if physics body was rotated externally (e.g., snap turn)
			var current_physics_rotation = physics_body.global_rotation.y
			var rotation_delta = abs(current_physics_rotation - last_physics_body_rotation_y)
			if rotation_delta > 0.01:  # Threshold to detect snap turns
				# Physics body was rotated - reset our rotation tracking
				# Keep the skeleton's current relative rotation
				var skeleton_relative_rotation = skeleton_instance.rotation.y - PI
				current_body_rotation_y = skeleton_relative_rotation
				target_body_rotation_y = skeleton_relative_rotation
				last_physics_body_rotation_y = current_physics_rotation
			
			# Get HMD forward direction
			var hmd_forward = -xr_camera.global_transform.basis.z
			hmd_forward.y = 0
			if hmd_forward.length() > 0.001:
				hmd_forward = hmd_forward.normalized()
				
				# Get capsule forward direction
				var capsule_forward = -physics_body.global_transform.basis.z
				capsule_forward.y = 0
				capsule_forward = capsule_forward.normalized()
				
				# Calculate angle between HMD and current body rotation
				var hmd_angle = capsule_forward.signed_angle_to(hmd_forward, Vector3.UP)
				var current_angle = skeleton_instance.rotation.y - PI  # Remove the 180° offset to get relative angle
				
				# Calculate angle difference
				var angle_diff = hmd_angle - current_angle
				# Normalize to -PI to PI range
				while angle_diff > PI:
					angle_diff -= TAU
				while angle_diff < -PI:
					angle_diff += TAU
				
				# Apply deadzone - only update target if outside deadzone
				var deadzone_rad = deg_to_rad(hmd_rotation_deadzone)
				if abs(angle_diff) > deadzone_rad:
					# Outside deadzone - update target rotation
					target_body_rotation_y = hmd_angle
				
				# Smoothly interpolate current rotation toward target
				var rotation_speed = body_rotation_smoothing * get_process_delta_time()
				current_body_rotation_y = lerp_angle(current_body_rotation_y, target_body_rotation_y, rotation_speed)
				
				# Apply the rotation (add 180° to face forward)
				skeleton_instance.rotation.y = current_body_rotation_y + PI
	else:
		# Fallback: skeleton is child of XROrigin - use global positioning
		var body_pos = xr_origin.global_position
		body_pos.y += body_height_offset
		
		skeleton_instance.global_position = body_pos
		
		# Optionally update rotation to follow HMD yaw
		if align_skeleton_with_hmd:
			var hmd_forward = -xr_camera.global_transform.basis.z
			hmd_forward.y = 0
			if hmd_forward.length() > 0.001:
				hmd_forward = hmd_forward.normalized()
				
				# Get current skeleton forward direction
				var skeleton_forward = -skeleton_instance.global_transform.basis.z
				skeleton_forward.y = 0
				skeleton_forward = skeleton_forward.normalized()
				
				# Calculate angle between HMD and current body rotation
				var hmd_angle = skeleton_forward.signed_angle_to(hmd_forward, Vector3.UP)
				
				# Apply deadzone - only update target if outside deadzone
				var deadzone_rad = deg_to_rad(hmd_rotation_deadzone)
				if abs(hmd_angle) > deadzone_rad:
					# Outside deadzone - update target rotation
					target_body_rotation_y = skeleton_instance.rotation.y + hmd_angle
				
				# Smoothly interpolate current rotation toward target
				var rotation_speed = body_rotation_smoothing * get_process_delta_time()
				current_body_rotation_y = lerp_angle(current_body_rotation_y, target_body_rotation_y, rotation_speed)
				
				# Apply the rotation
				skeleton_instance.rotation.y = current_body_rotation_y

## Update seated mode by adjusting VRLocomotion's height offset
func _update_seated_mode():
	# Find VRLocomotion component to update its height offset
	var vr_locomotion = xr_origin.get_node_or_null("VRLocomotion")
	if not vr_locomotion:
		if show_debug_logs:
			print("VRIKComponent: VRLocomotion not found, cannot apply seated mode offset")
		return
	
	if seated_mode and not seated_mode_active:
		# Set VRLocomotion's hmd_height_offset to raise the origin
		# This makes tracking appear higher (physics_body.y + positive offset = higher XROrigin)
		vr_locomotion.hmd_height_offset = seated_height_offset
		
		seated_mode_active = true
		
		if show_debug_logs:
			print("VRIKComponent: Seated mode enabled - hmd_height_offset = ", seated_height_offset, "m")
		
	elif not seated_mode and seated_mode_active:
		# Restore origin to floor level
		vr_locomotion.hmd_height_offset = 0.0
		
		seated_mode_active = false
		
		if show_debug_logs:
			print("VRIKComponent: Seated mode disabled - hmd_height_offset restored")

## Set the skeletal mesh to be controlled by this IK system
func set_skeleton_mesh(new_skeleton: Skeleton3D):
	skeleton = new_skeleton
	if skeleton and not Engine.is_editor_hint():
		_cache_bone_indices()

## Recache bone indices if bone names change
func refresh_bone_cache():
	_cache_bone_indices()

## Load and instance the skeletal mesh scene
func _load_skeletal_mesh():
	# Clean up existing instance
	if skeleton_instance:
		skeleton_instance.queue_free()
		skeleton_instance = null
		skeleton = null
	
	if not skeletal_mesh_scene:
		return
	
	# Instance the skeletal mesh
	skeleton_instance = skeletal_mesh_scene.instantiate()
	skeleton_instance.name = "SkeletalMesh_IK"
	
	# Try to find the physics body (capsule) to parent to if integration is enabled
	var physics_body = _find_physics_body() if use_locomotion_integration else null
	if physics_body:
		# Parent to the physics body so skeleton rotates with snap turns
		physics_body.add_child(skeleton_instance)
		skeleton_needs_reparenting = false
		
		if show_debug_logs:
			print("=== SKELETON INITIALIZATION ===")
			print("Physics body position: ", physics_body.global_position)
			print("Skeleton default local position: ", skeleton_instance.position)
		
		# Set initial local rotation relative to capsule
		if align_skeleton_with_hmd and xr_camera:
			# Get HMD forward direction
			var hmd_forward = -xr_camera.global_transform.basis.z
			hmd_forward.y = 0
			hmd_forward = hmd_forward.normalized()
			
			# Get capsule forward direction
			var capsule_forward = -physics_body.global_transform.basis.z
			capsule_forward.y = 0
			capsule_forward = capsule_forward.normalized()
			
			# Calculate relative angle (add 180 to face forward)
			var angle = capsule_forward.signed_angle_to(hmd_forward, Vector3.UP)
			skeleton_instance.rotation.y = angle + PI
		else:
			# No HMD alignment - face forward relative to capsule (180° from default)
			skeleton_instance.rotation.y = PI
		
		if show_debug_logs:
			print("VRIKComponent: Skeleton parented to physics body (locomotion integration)")
	else:
		# Physics body doesn't exist yet or integration disabled - parent to XROrigin
		xr_origin.add_child(skeleton_instance)
		skeleton_needs_reparenting = use_locomotion_integration  # Only retry if integration is enabled
		
		# Set initial global rotation based on HMD
		if align_skeleton_with_hmd and xr_camera:
			var hmd_forward = -xr_camera.global_transform.basis.z
			hmd_forward.y = 0
			hmd_forward = hmd_forward.normalized()
			
			var skeleton_forward = -Vector3.FORWARD
			var angle = skeleton_forward.signed_angle_to(hmd_forward, Vector3.UP)
			skeleton_instance.rotation.y = angle
		
		if show_debug_logs:
			if use_locomotion_integration:
				print("VRIKComponent: Physics body not found yet, will retry reparenting...")
			else:
				print("VRIKComponent: Skeleton parented to XROrigin (locomotion integration disabled)")
	
	# No longer need this block - rotation is handled above
	# Align skeleton with HMD direction if enabled
	# if align_skeleton_with_hmd and xr_camera:
	
	# Find the Skeleton3D in the instance
	skeleton = _find_skeleton_recursive(skeleton_instance)
	
	if skeleton:
		if show_debug_logs:
			print("Loaded skeletal mesh and found Skeleton3D at: ", skeleton.get_path())
		
		# Try to auto-configure bone names
		if _auto_configure_bones():
			if show_debug_logs:
				print("Successfully auto-configured bone mappings!")
		else:
			print("WARNING: Could not auto-detect bones. Please manually configure bone names.")
			if show_debug_logs:
				_print_all_bones()
		
		_cache_bone_indices()
	else:
		push_error("Could not find Skeleton3D in the instantiated skeletal mesh scene")

## Helper function to convert Euler angles to Basis with specified rotation order
func _get_rotation_from_euler(rotation_degrees: Vector3, rotation_order: int, mirror: bool) -> Basis:
	# Mirror rotation if needed (for right hand)
	var final_rotation = rotation_degrees
	if mirror:
		# Mirror Y and Z rotations (flip around X axis)
		final_rotation = Vector3(rotation_degrees.x, -rotation_degrees.y, -rotation_degrees.z)
	
	# Apply hand rotation offset using specified order
	var offset_quat = Quaternion.IDENTITY
	var rot_rad = final_rotation * PI / 180.0
	
	# Apply rotations in the specified order
	match rotation_order:
		0: # XYZ
			offset_quat = Quaternion(Vector3.RIGHT, rot_rad.x) * Quaternion(Vector3.UP, rot_rad.y) * Quaternion(Vector3.BACK, rot_rad.z)
		1: # XZY
			offset_quat = Quaternion(Vector3.RIGHT, rot_rad.x) * Quaternion(Vector3.BACK, rot_rad.z) * Quaternion(Vector3.UP, rot_rad.y)
		2: # YXZ
			offset_quat = Quaternion(Vector3.UP, rot_rad.y) * Quaternion(Vector3.RIGHT, rot_rad.x) * Quaternion(Vector3.BACK, rot_rad.z)
		3: # YZX
			offset_quat = Quaternion(Vector3.UP, rot_rad.y) * Quaternion(Vector3.BACK, rot_rad.z) * Quaternion(Vector3.RIGHT, rot_rad.x)
		4: # ZXY
			offset_quat = Quaternion(Vector3.BACK, rot_rad.z) * Quaternion(Vector3.RIGHT, rot_rad.x) * Quaternion(Vector3.UP, rot_rad.y)
		5: # ZYX
			offset_quat = Quaternion(Vector3.BACK, rot_rad.z) * Quaternion(Vector3.UP, rot_rad.y) * Quaternion(Vector3.RIGHT, rot_rad.x)
	
	return Basis(offset_quat)

## Create debug axes visualization for controllers
func _create_debug_axes():
	if left_controller:
		left_hand_axes = _create_axes_mesh()
		left_controller.add_child(left_hand_axes)
	
	if right_controller:
		right_hand_axes = _create_axes_mesh()
		right_controller.add_child(right_hand_axes)

## Create a mesh showing X(red), Y(green), Z(blue) axes
func _create_axes_mesh() -> Node3D:
	var axes = Node3D.new()
	
	# X axis (red)
	var x_mesh = MeshInstance3D.new()
	var x_cyl = CylinderMesh.new()
	x_cyl.top_radius = 0.005
	x_cyl.bottom_radius = 0.005
	x_cyl.height = 0.1
	x_mesh.mesh = x_cyl
	x_mesh.position = Vector3(0.05, 0, 0)
	x_mesh.rotation_degrees = Vector3(0, 0, 90)
	var x_mat = StandardMaterial3D.new()
	x_mat.albedo_color = Color.RED
	x_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	x_mesh.material_override = x_mat
	axes.add_child(x_mesh)
	
	# Y axis (green)
	var y_mesh = MeshInstance3D.new()
	var y_cyl = CylinderMesh.new()
	y_cyl.top_radius = 0.005
	y_cyl.bottom_radius = 0.005
	y_cyl.height = 0.1
	y_mesh.mesh = y_cyl
	y_mesh.position = Vector3(0, 0.05, 0)
	var y_mat = StandardMaterial3D.new()
	y_mat.albedo_color = Color.GREEN
	y_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	y_mesh.material_override = y_mat
	axes.add_child(y_mesh)
	
	# Z axis (blue)
	var z_mesh = MeshInstance3D.new()
	var z_cyl = CylinderMesh.new()
	z_cyl.top_radius = 0.005
	z_cyl.bottom_radius = 0.005
	z_cyl.height = 0.1
	z_mesh.mesh = z_cyl
	z_mesh.position = Vector3(0, 0, 0.05)
	z_mesh.rotation_degrees = Vector3(90, 0, 0)
	var z_mat = StandardMaterial3D.new()
	z_mat.albedo_color = Color.BLUE
	z_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	z_mesh.material_override = z_mat
	axes.add_child(z_mesh)
	
	return axes

## Update debug axes visibility
func _update_debug_axes():
	if not show_controller_axes:
		if left_hand_axes:
			left_hand_axes.queue_free()
			left_hand_axes = null
		if right_hand_axes:
			right_hand_axes.queue_free()
			right_hand_axes = null
	elif not left_hand_axes or not right_hand_axes:
		_create_debug_axes()

## Recursively search for Skeleton3D node
func _find_skeleton_recursive(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	
	for child in node.get_children():
		var result = _find_skeleton_recursive(child)
		if result:
			return result
	
	return null

## Find the physics body (capsule) created by VRLocomotion
func _find_physics_body() -> CharacterBody3D:
	# The physics body is typically added to XROrigin's parent
	if not xr_origin:
		return null
	
	var parent = xr_origin.get_parent()
	if not parent:
		return null
	
	# Look for a CharacterBody3D named "PhysicsBody"
	for child in parent.get_children():
		if child is CharacterBody3D and child.name == "PhysicsBody":
			return child
	
	return null

## Try to reparent skeleton to physics body if it becomes available
func _try_reparent_to_physics_body():
	if not skeleton_instance or not skeleton_needs_reparenting or not use_locomotion_integration:
		return
	
	var physics_body = _find_physics_body()
	if physics_body:
		# Physics body now exists! Reparent the skeleton
		# Store the current global position we want to keep
		var current_global_pos = skeleton_instance.global_position
		
		# Remove from current parent
		skeleton_instance.get_parent().remove_child(skeleton_instance)
		
		# Add to physics body
		physics_body.add_child(skeleton_instance)
		
		# Convert global rotation to local rotation relative to physics body
		if align_skeleton_with_hmd and xr_camera:
			# Recalculate rotation relative to capsule
			var hmd_forward = -xr_camera.global_transform.basis.z
			hmd_forward.y = 0
			hmd_forward = hmd_forward.normalized()
			
			var capsule_forward = -physics_body.global_transform.basis.z
			capsule_forward.y = 0
			capsule_forward = capsule_forward.normalized()
			
			var angle = capsule_forward.signed_angle_to(hmd_forward, Vector3.UP)
			skeleton_instance.rotation.y = angle + PI
		else:
			# Just face forward relative to capsule (180° from default)
			skeleton_instance.rotation.y = PI
		
		# Keep the same global position
		skeleton_instance.global_position = current_global_pos
		
		skeleton_needs_reparenting = false
		
		if show_debug_logs:
			print("VRIKComponent: Successfully reparented skeleton to physics body!")
			print("  Skeleton local rotation Y: ", skeleton_instance.rotation_degrees.y)
			print("  Physics body rotation Y: ", physics_body.rotation_degrees.y)

## Print all available bones in the skeleton
func _print_all_bones():
	if not skeleton:
		return
	
	print("\n=== AVAILABLE BONES IN SKELETON ===")
	print("Total bones: ", skeleton.get_bone_count())
	print("\nAll bone names:")
	
	for i in range(skeleton.get_bone_count()):
		var bone_name = skeleton.get_bone_name(i)
		print("  [", i, "] \"", bone_name, "\"")
	
	print("\n=== AUTO-DETECTED SUGGESTIONS ===")
	_print_bone_suggestions()
	print("===================================\n")

## Try to auto-configure bone names by detecting common patterns
func _auto_configure_bones() -> bool:
	if not skeleton:
		return false
	
	var found_count = 0
	var suggestions = {}
	
	for i in range(skeleton.get_bone_count()):
		var bone_name = skeleton.get_bone_name(i)
		var lower = bone_name.to_lower()
		
		# Head
		if "head" in lower and "end" not in lower and "top" not in lower and not "head_bone_name" in suggestions:
			suggestions["head_bone_name"] = bone_name
		
		# Neck
		if "neck" in lower and not "neck_bone_name" in suggestions:
			suggestions["neck_bone_name"] = bone_name
		
		# Spine (prefer upper spine)
		if "spine" in lower:
			if not "spine_bone_name" in suggestions or "2" in lower or "upper" in lower or "chest" in lower:
				suggestions["spine_bone_name"] = bone_name
		
		# Hips
		if ("hip" in lower or "pelvis" in lower) and not "hips_bone_name" in suggestions:
			suggestions["hips_bone_name"] = bone_name
		
		# Left arm bones
		if "left" in lower or bone_name.begins_with("L_") or bone_name.begins_with("L.") or ".l" in lower:
			if "shoulder" in lower and not "left_shoulder_bone_name" in suggestions:
				suggestions["left_shoulder_bone_name"] = bone_name
			elif ("upperarm" in lower or ("arm" in lower and "forearm" not in lower and "fore" not in lower)) and not "left_arm_bone_name" in suggestions:
				suggestions["left_arm_bone_name"] = bone_name
			elif ("forearm" in lower or "lowerarm" in lower) and not "left_forearm_bone_name" in suggestions:
				suggestions["left_forearm_bone_name"] = bone_name
			elif "hand" in lower and "end" not in lower and "thumb" not in lower and "index" not in lower and "middle" not in lower and "ring" not in lower and "pinky" not in lower and not "left_hand_bone_name" in suggestions:
				suggestions["left_hand_bone_name"] = bone_name
		
		# Right arm bones
		if "right" in lower or bone_name.begins_with("R_") or bone_name.begins_with("R.") or ".r" in lower:
			if "shoulder" in lower and not "right_shoulder_bone_name" in suggestions:
				suggestions["right_shoulder_bone_name"] = bone_name
			elif ("upperarm" in lower or ("arm" in lower and "forearm" not in lower and "fore" not in lower)) and not "right_arm_bone_name" in suggestions:
				suggestions["right_arm_bone_name"] = bone_name
			elif ("forearm" in lower or "lowerarm" in lower) and not "right_forearm_bone_name" in suggestions:
				suggestions["right_forearm_bone_name"] = bone_name
			elif "hand" in lower and "end" not in lower and "thumb" not in lower and "index" not in lower and "middle" not in lower and "ring" not in lower and "pinky" not in lower and not "right_hand_bone_name" in suggestions:
				suggestions["right_hand_bone_name"] = bone_name
		
		# Left leg bones
		if "left" in lower or bone_name.begins_with("L_") or bone_name.begins_with("L.") or ".l" in lower:
			if ("upleg" in lower or "upperleg" in lower or "thigh" in lower) and not "left_upleg_bone_name" in suggestions:
				suggestions["left_upleg_bone_name"] = bone_name
			elif ("leg" in lower or "calf" in lower or "shin" in lower) and "upleg" not in lower and "upper" not in lower and "thigh" not in lower and not "left_leg_bone_name" in suggestions:
				suggestions["left_leg_bone_name"] = bone_name
			elif "foot" in lower and "end" not in lower and "toe" not in lower and not "left_foot_bone_name" in suggestions:
				suggestions["left_foot_bone_name"] = bone_name
		
		# Right leg bones
		if "right" in lower or bone_name.begins_with("R_") or bone_name.begins_with("R.") or ".r" in lower:
			if ("upleg" in lower or "upperleg" in lower or "thigh" in lower) and not "right_upleg_bone_name" in suggestions:
				suggestions["right_upleg_bone_name"] = bone_name
			elif ("leg" in lower or "calf" in lower or "shin" in lower) and "upleg" not in lower and "upper" not in lower and "thigh" not in lower and not "right_leg_bone_name" in suggestions:
				suggestions["right_leg_bone_name"] = bone_name
			elif "foot" in lower and "end" not in lower and "toe" not in lower and not "right_foot_bone_name" in suggestions:
				suggestions["right_foot_bone_name"] = bone_name
	
	# Apply detected bone names
	if suggestions.has("head_bone_name"):
		head_bone_name = suggestions["head_bone_name"]
		found_count += 1
	if suggestions.has("neck_bone_name"):
		neck_bone_name = suggestions["neck_bone_name"]
		found_count += 1
	if suggestions.has("spine_bone_name"):
		spine_bone_name = suggestions["spine_bone_name"]
		found_count += 1
	if suggestions.has("hips_bone_name"):
		hips_bone_name = suggestions["hips_bone_name"]
		found_count += 1
	if suggestions.has("left_shoulder_bone_name"):
		left_shoulder_bone_name = suggestions["left_shoulder_bone_name"]
		found_count += 1
	if suggestions.has("left_arm_bone_name"):
		left_arm_bone_name = suggestions["left_arm_bone_name"]
		found_count += 1
	if suggestions.has("left_forearm_bone_name"):
		left_forearm_bone_name = suggestions["left_forearm_bone_name"]
		found_count += 1
	if suggestions.has("left_hand_bone_name"):
		left_hand_bone_name = suggestions["left_hand_bone_name"]
		found_count += 1
	if suggestions.has("right_shoulder_bone_name"):
		right_shoulder_bone_name = suggestions["right_shoulder_bone_name"]
		found_count += 1
	if suggestions.has("right_arm_bone_name"):
		right_arm_bone_name = suggestions["right_arm_bone_name"]
		found_count += 1
	if suggestions.has("right_forearm_bone_name"):
		right_forearm_bone_name = suggestions["right_forearm_bone_name"]
		found_count += 1
	if suggestions.has("right_hand_bone_name"):
		right_hand_bone_name = suggestions["right_hand_bone_name"]
		found_count += 1
	if suggestions.has("left_upleg_bone_name"):
		left_upleg_bone_name = suggestions["left_upleg_bone_name"]
		found_count += 1
	if suggestions.has("left_leg_bone_name"):
		left_leg_bone_name = suggestions["left_leg_bone_name"]
		found_count += 1
	if suggestions.has("left_foot_bone_name"):
		left_foot_bone_name = suggestions["left_foot_bone_name"]
		found_count += 1
	if suggestions.has("right_upleg_bone_name"):
		right_upleg_bone_name = suggestions["right_upleg_bone_name"]
		found_count += 1
	if suggestions.has("right_leg_bone_name"):
		right_leg_bone_name = suggestions["right_leg_bone_name"]
		found_count += 1
	if suggestions.has("right_foot_bone_name"):
		right_foot_bone_name = suggestions["right_foot_bone_name"]
		found_count += 1
	
	# Return true if we found at least head and both hands
	return found_count >= 3 and suggestions.has("head_bone_name") and suggestions.has("left_hand_bone_name") and suggestions.has("right_hand_bone_name")

## Try to auto-detect and suggest bone names
func _print_bone_suggestions():
	var suggestions = {}
	
	for i in range(skeleton.get_bone_count()):
		var bone_name = skeleton.get_bone_name(i)
		var lower = bone_name.to_lower()
		
		# Head
		if "head" in lower and "end" not in lower and "top" not in lower and not "head_bone_name" in suggestions:
			suggestions["head_bone_name"] = bone_name
		
		# Neck
		if "neck" in lower and not "neck_bone_name" in suggestions:
			suggestions["neck_bone_name"] = bone_name
		
		# Spine (prefer upper spine)
		if "spine" in lower:
			if not "spine_bone_name" in suggestions or "2" in lower or "upper" in lower or "chest" in lower:
				suggestions["spine_bone_name"] = bone_name
		
		# Hips
		if ("hip" in lower or "pelvis" in lower) and not "hips_bone_name" in suggestions:
			suggestions["hips_bone_name"] = bone_name
		
		# Left arm bones
		if "left" in lower or bone_name.begins_with("L_") or bone_name.begins_with("L.") or ".l" in lower:
			if "shoulder" in lower and not "left_shoulder_bone_name" in suggestions:
				suggestions["left_shoulder_bone_name"] = bone_name
			elif ("upperarm" in lower or ("arm" in lower and "forearm" not in lower)) and not "left_arm_bone_name" in suggestions:
				suggestions["left_arm_bone_name"] = bone_name
			elif ("forearm" in lower or "lowerarm" in lower) and not "left_forearm_bone_name" in suggestions:
				suggestions["left_forearm_bone_name"] = bone_name
			elif "hand" in lower and "end" not in lower and not "left_hand_bone_name" in suggestions:
				suggestions["left_hand_bone_name"] = bone_name
		
		# Right arm bones
		if "right" in lower or bone_name.begins_with("R_") or bone_name.begins_with("R.") or ".r" in lower:
			if "shoulder" in lower and not "right_shoulder_bone_name" in suggestions:
				suggestions["right_shoulder_bone_name"] = bone_name
			elif ("upperarm" in lower or ("arm" in lower and "forearm" not in lower)) and not "right_arm_bone_name" in suggestions:
				suggestions["right_arm_bone_name"] = bone_name
			elif ("forearm" in lower or "lowerarm" in lower) and not "right_forearm_bone_name" in suggestions:
				suggestions["right_forearm_bone_name"] = bone_name
			elif "hand" in lower and "end" not in lower and not "right_hand_bone_name" in suggestions:
				suggestions["right_hand_bone_name"] = bone_name
	
	if suggestions.is_empty():
		print("Could not auto-detect bone names. Please set them manually using the bone list above.")
	else:
		print("Suggested bone mappings:")
		for key in suggestions:
			print("  ", key, " = \"", suggestions[key], "\"")
