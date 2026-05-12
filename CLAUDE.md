# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Wolf of Hoh Xil — a Godot 4.6 top-down game where the player controls a wolf crossing a highway, dodging vehicles, collecting food, and avoiding a ranger's vision cone. The main scene is `highway.tscn`.

All source files live under `src/` — see [Source Structure](#source-structure) below.

## Technology Stack

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Version Control**: Git with trunk-based development
- **Renderer**: Forward Plus (D3D12 on Windows)
- **Physics**: Jolt Physics

## Run the Game

```bash
godot --path .
```
Or open `highway.tscn` in the Godot editor and press F5.

### Run Smoke Test

```bash
"/c/Users/Binwei Kang/OneDrive/Desktop/Godot_v4.6.1-stable_win64.exe/Godot_v4.6.1-stable_win64_console.exe" --headless --path . --script res://tests/smoke_test.gd
```

### Chapter Publishing (章节发布)

每章大更新完成后，使用以下方式自动推送到 GitHub：

```bash
# 方式1: 手动脚本
bash tools/chapter_publish.sh <章节号> "<描述>"

# 方式2: 提交信息以 "Chapter" 开头，hook 自动推送+打tag
git commit -m "Chapter 2: 荒野探索 — 狼同伴系统"
# → auto-push hook 自动执行 git push + git tag ch2
```

已设置 `PostToolUse` hook：任何 `git commit` 信息以 "Chapter" 开头时，自动推送到 `origin/main` 并打对应版本 tag。

**GitHub**: https://github.com/KingBinwei/wolf-of-hoh-xil
**Tags**: `ch1`, `ch2`, ...

## Engine Version Reference

Docs: [Godot 4.6](https://docs.godotengine.org/en/4.6/)

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

## Source Structure

```
src/
├── scenes/                   ← .tscn scene files
│   ├── highway.tscn          (main scene)
│   ├── wolf.tscn             (player wolf)
│   └── wilds.tscn            (placeholder)
├── scripts/
│   ├── core/                 ← game state, main loop
│   │   └── highway_main.gd
│   ├── player/               ← wolf controller + physics
│   │   └── wolf_controller.gd
│   ├── ui/                   ← UI scripts
│   │   └── wolf_ui.gd
│   ├── vehicles/             ← vehicle spawning + behavior
│   │   ├── vehicle.gd
│   │   └── vehicle_spawner.gd
│   ├── npc/                  ← ranger, future companions, competitors
│   │   └── ranger_vision.gd
│   ├── items/                ← food and future pickups
│   │   └── food.gd
│   └── world/                ← background, weather, environment
│       └── parallax_background.gd
└── assets/                   ← textures, audio (future)
    ├── road.png
    └── wolf.png
```

### Key Scripts (with paths)

| File | Class | Role |
|------|-------|------|
| `src/scripts/core/highway_main.gd` | Node2D | Scene root. Road fitting, camera + world node creation, geometry-dependent configuration, food spawning, game-over + restart (R key) |
| `src/scripts/player/wolf_controller.gd` | CharacterBody2D | Arrow-key movement, health/hunger stats, vehicle/food detection via hitbox Area2D, emits `game_over` / `food_eaten` |
| `src/scripts/ui/wolf_ui.gd` | CanvasLayer | Health bar, hunger bar, score label, game-over overlay — all built in code via `_build_ui()` |
| `src/scripts/vehicles/vehicle_spawner.gd` | Node2D | 4 lanes: left 2 go up (-Y), right 2 go down (+Y). 6 vehicle types, min 1.5s gap, vehicles self-despawn offscreen |
| `src/scripts/vehicles/vehicle.gd` | Area2D (`class_name Vehicle`) | 6 `VehicleType` enums, `_draw()` procedural body+wheels+stripes |
| `src/scripts/npc/ranger_vision.gd` | Node2D | Right-facing vision cone with raycast-per-sample occlusion (blocked by vehicles on layer 1), vertical sine-wave drift, emits `wolf_detected` |
| `src/scripts/items/food.gd` | Area2D (`class_name FoodItem`) | 4 types (`BURGER, EGG_TART, BONE, FISH`), `_draw()` visuals, 10s lifetime with 2s fade-out |
| `src/scripts/world/parallax_background.gd` | ParallaxBackground | Exposes `scroll_speed` in the editor; `highway_main.gd` sets it to 0 at startup |

## Architecture

### Scene Tree (highway.tscn)

```
Highway (Node2D)                          — highway_main.gd
├─ ParallaxBackground                     — parallax_background.gd (scrolling stopped at startup)
│  └─ ParallaxLayer → Sprite2D (road texture)
├─ Camera2D (created in code)
├─ Wolf (CharacterBody2D, from wolf.tscn) — wolf_controller.gd
│  ├─ Sprite2D
│  ├─ CollisionShape2D (physics body)
│  └─ Hitbox (Area2D, created in code — detects vehicles + food)
├─ WolfUI (CanvasLayer, created in code)  — wolf_ui.gd
├─ Ranger (Node2D, created in code)       — ranger_vision.gd
└─ VehicleSpawner (Node2D, created in code) — vehicle_spawner.gd
```

Highway, ParallaxBackground, and the Wolf (`src/scenes/wolf.tscn`) are pre-placed in the scene. WolfUI, Ranger, VehicleSpawner, and Camera2D are instantiated programmatically in `src/scripts/core/highway_main.gd:_spawn_world_nodes()` and `_setup_camera()`. Each spawned node is configured via a `.configure(...)` method after creation.

### Collision Layers

- **Layer 1**: Vehicles — raycast occlusion (ranger vision) + wolf hitbox detection
- **Layer 2**: Food — wolf hitbox detection

The wolf hitbox (Area2D) has `collision_mask = 0b11` to detect both layers. Vehicle Area2Ds have `collision_layer = 1`. Food Area2Ds have `collision_layer = 2`.

### Game Loop

1. Vehicles spawn continuously in 4 lanes (left 2 move up, right 2 move down)
2. Player moves wolf with arrow keys at `move_speed` (default 200 px/s), clamped to road bounds
3. Vehicle hit → -25 HP, 0.5s invincibility (sprite alpha flicker)
4. Food pickup → restores hunger by type (25–40), score +1
5. Hunger increases steadily; when full, health drains. Both rates are `@export` tunable
6. Ranger cone hits wolf (line-of-sight not blocked by a vehicle) → game over
7. Health reaches 0 → game over. Game over overlay appears; R to reload scene

### Coding Conventions

- Signal-based communication (`game_over`, `food_eaten`, `wolf_detected`)
- `_draw()` for all procedural visuals (vehicles, food, ranger cone)
- `class_name` on reusable types: `Vehicle`, `FoodItem`
- Nodes created at runtime receive a `.configure(...)` method rather than constructor args
- `@export` for tunable values visible in the Godot editor
- Private members prefixed with `_`
- Godot `.uid` files (e.g., `food.gd.uid`) are auto-generated and must be committed

## Agent Studio Context

This project uses the Claude Code Game Studios agent architecture. Key reference files in `.claude/docs/`:

| File | When to read |
|------|-------------|
| `coordination-rules.md` | Agent delegation, model tiers, parallel agent patterns |
| `coding-standards.md` | Coding/testing standards for new work (aspirational — existing code predates these) |
| `context-management.md` | Context budget strategies, file-backed state, subagent delegation |
| `agent-roster.md` | Full list of 48+ available agents and when to use each |
| `director-gates.md` | Gate prompts for director/lead reviews |
| `technical-preferences.md` | Performance budgets, naming conventions (mostly unconfigured) |

### Design Documents

| File | Content |
|------|---------|
| `design/gdd/highway-survival.md` | 完整游戏设计文档 — 6章节制，狼同伴系统，博弈机制，5种结局 |

Hooks and permissions live in `.claude/settings.json` + `.claude/hooks/`.

## Auto-Routing Rules (自动调度协议)

当用户消息涉及游戏设计、架构或实现时，**不要直接回答**。自动 spawn `router` Agent 进行调度。Router 会根据输入内容将任务路由到正确的流水线。

### Two Pipelines

```
Pipeline A: Design Triangle
  cyberneticist ←→ phenomenologist → deconstructor
  (系统设计)      (叙事/世界观)       (审查/找茬)

Pipeline B: Implementation Pipeline
  structural-architect → gdscript-geek → ci-judge
  (场景树/信号/状态机)   (数学/物理/GDScript) (CI裁决)
```

### Quick Dispatch

| 用户输入特征 | 流水线 | 启动 Agent |
|---|---|---|
| 设计、系统、机制、数值、公式、平衡、资源循环 | A | cyberneticist |
| 叙事、世界观、文本、调性、氛围、角色 | A | phenomenologist |
| 审查、找茬、最优解、漏洞、exploit | A | deconstructor |
| 场景树、信号、状态机、节点规划 | B | structural-architect |
| 写代码、实现函数、数学运算、GDScript | B | gdscript-geek |
| 测试、报错、CI、stderr | B | ci-judge |
| 完整功能（从设计到代码） | A→B | router 编排全链 |
| 模糊请求 | Router | router 先分类 |

### Auto-Handoff Chain

每个 Agent 完成后**自动** spawn 链中的下一个 Agent，无需用户手动触发：

- **cyberneticist** → phenomenologist (叙事) 或 deconstructor (审查)
- **phenomenologist** → cyberneticist (需要系统支撑) 或 deconstructor (审查)
- **deconstructor** → 被拒 Agent (修正) 或 structural-architect (进入实现)
- **structural-architect** → gdscript-geek (必须，无例外)
- **gdscript-geek** → ci-judge (必须，无例外)
- **ci-judge** → structural-architect (架构错误) 或 gdscript-geek (实现错误) 或 PASS (放行)
- **3次重试同一错误** → 停止自动交接，升级给用户
