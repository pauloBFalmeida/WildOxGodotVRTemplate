# Wild Ox Godot VR/XR Template

> Note: Main requires Godot 4.5 or later and each branch will have locked minor version numbers

This project is best ran on HMDs in compatability renderer.

- Quest 2 and 3 can run mobile rendering @ 72hz
- Anything above 72hz becomes quite taxing on the Q2 in mobile rendering
- Currently set to Compatabilty Rendering & MSAA 4x (running smooth on q2/q3)

## Features

### VR IK System

- **Full-body IK with SkeletonIK3D:** Head, arms, and legs track VR controllers and HMD
- **Dynamic crouching:** Legs automatically solve IK when player crouches
- **Configurable hand tracking:** Adjust hand rotation/position offsets to match your avatar
- **Locomotion integration:** IK system works seamlessly with physical VR movement
- **Debug visualization:** Real-time skeleton mirror for tuning IK behavior (see `scenes/debug/`)

### Rendering Features

- **Fast Sky Node:** Fully dynamic day/night cycle with procedural clouds
- **Optimized lighting:** Baked lightmaps with dynamic shadow support
- **MSAA 4x:** Smooth visuals on Quest 2/3 hardware

### VR Movement & Controls

- **Physically based locomotion:** Smooth movement with physics capsule collision
- **Snap turning:** Configurable snap angles (45°, 90°, etc.)
- **Smooth turning:** Optional analog stick rotation
- **Jump mechanics:** Natural VR jumping with physics
- **Velocity averaging:** Smooth hand tracking for throwing/interactions

### Testing Tools

- **VRPlayer:** Instant VR testing with full-body IK and physical locomotion
- **FPSPlayer:** Navigate maps without HMD for level design
- **Debug mirror:** External skeleton view for IK tuning (drag & drop, auto-detection)

## Quick Start

1. **Open in Godot 4.4+**
2. **Run the project:** The main scene will automatically detect your HMD
   - **With HMD:** Loads VRPlayer with full-body IK and VR controls
   - **Without HMD:** Automatically falls back to FPSPlayer for desktop testing
3. **Tune IK:** Add `scenes/debug/SkeletonDebugMirror.tscn` to see skeleton tracking in VR

## Key Scripts

- **VRIKComponent.gd:** Full-body IK system using SkeletonIK3D
- **VRLocomotion.gd:** Physically based VR movement with snap/smooth turning
- **VRHandCollider.gd:** Hand collision and grip interaction
- **VRIKDebugMirror.gd:** Real-time skeleton visualization for debugging
- **velocity_averager.gd:** Smooth velocity tracking for throwing mechanics

## Meta Platform SDK Integration

This template includes Meta Platform SDK integration for Quest development:

- Achievements (simple, count, and bitfield)
- Downloadable content
- Displaying bidirectional followers that also own the app
- Displaying user's name, profile image, and entitlement status

For more info on using the Platform SDK, see [Getting Started with the Meta Platform SDK](https://godot-sdk-integrations.github.io/godot-meta-toolkit/manual/platform_sdk/getting_started.html) in the official docs.

## Support

Wild Ox Discord & Support: https://discord.gg/gNaryjZwnZ
