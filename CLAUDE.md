# Claude Code Game Studios -- Game Studio Agent Architecture

Indie game development managed through 48 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concern and quality.

## Technology Stack

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Version Control**: Git with trunk-based development

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

Docs: [Godot 4.6](https://docs.godotengine.org/en/4.6/)

## Technical Preferences

@.claude/docs/technical-preferences.md

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

## Project Overview

A Godot 4.6 top-down game where the player controls a wolf crossing a highway, dodging vehicles, collecting food, and avoiding a ranger's vision cone. The main scene is `highway.tscn`.

## Run the Game

```bash
godot --path "g:\Wolf of Hoh Xil\wolf-of-hoh-xil"
```
Or open `highway.tscn` in the Godot editor and press F5.

## Architecture

### Scene Tree (highway.tscn)
```
Highway (Node2D)  — highway_main.gd
├─ ParallaxBackground  — parallax_background.gd
│  └─ ParallaxLayer → Sprite2D (road texture)
├─ Wolf (CharacterBody2D)  — wolf_controller.gd
│  ├─ Sprite2D
│  ├─ CollisionShape2D (disabled)
│  └─ Hitbox (Area2D, created in code)
├─ WolfUI (CanvasLayer)  — wolf_ui.gd
├─ Ranger (Node2D)  — ranger_vision.gd
└─ VehicleSpawner (Node2D)  — vehicle_spawner.gd
```

### Key Scripts

| File | Role |
|------|------|
| `highway_main.gd` | Game state, node init, food spawning, restart |
| `wolf_controller.gd` | Player input, movement, health/hunger, emits `game_over`/`food_eaten` |
| `wolf_ui.gd` | Health bar, hunger bar, score, game-over overlay |
| `vehicle_spawner.gd` | 4-lane spawner, 6 vehicle types, min 1.5s gap |
| `vehicle.gd` | Vehicle Area2D with `_draw()` visuals |
| `ranger_vision.gd` | Left-side patrol, raycast cone vision, emits `wolf_detected` |
| `food.gd` | FoodItem Area2D, 4 types, `_draw()` visuals, 10s lifetime |

### Collision Layers

- **Layer 1**: Vehicles (raycast occlusion + wolf hitbox)
- **Layer 2**: Food (wolf hitbox detection)

### Game Loop

1. Vehicles spawn in 4 alternating lanes
2. Player moves wolf with arrow keys (200 px/s)
3. Vehicle hit → -25 HP, 0.5s invincibility
4. Food pickup → restores hunger
5. Hunger fills at 4/s; at max, health drains 7/s
6. Ranger cone or health=0 → game over overlay + R to restart

### Coding Conventions

- GDScript, Godot 4.6
- Signal-based communication
- `_draw()` for procedural visuals
- `class_name` for reusable types (Vehicle, FoodItem)
- Private members prefixed with `_`
