# Agent Roster

The following agents are available. Each has a dedicated definition file in
`.claude/agents/`. Use the agent best suited to the task at hand. When a task
spans multiple domains, the coordinating agent (usually `producer` or the
domain lead) should delegate to specialists.

## Tier 1 -- Leadership Agents (Opus)
| Agent | Domain | When to Use |
|-------|--------|-------------|
| `creative-director` | High-level vision | Major creative decisions, pillar conflicts, tone/direction |
| `technical-director` | Technical vision | Architecture decisions, tech stack choices, performance strategy |
| `producer` | Production management | Sprint planning, milestone tracking, risk management, coordination |

## Tier 2 -- Department Lead Agents (Sonnet)
| Agent | Domain | When to Use |
|-------|--------|-------------|
| `game-designer` | Game design | Mechanics, systems, progression, economy, balancing |
| `lead-programmer` | Code architecture | System design, code review, API design, refactoring |
| `art-director` | Visual direction | Style guides, art bible, asset standards, UI/UX direction |
| `audio-director` | Audio direction | Music direction, sound palette, audio implementation strategy |
| `narrative-director` | Story and writing | Story arcs, world-building, character design, dialogue strategy |
| `qa-lead` | Quality assurance | Test strategy, bug triage, release readiness, regression planning |
| `release-manager` | Release pipeline | Build management, versioning, changelogs, deployment, rollbacks |
| `localization-lead` | Internationalization | String externalization, translation pipeline, locale testing |

## Tier 3 -- Specialist Agents (Sonnet or Haiku)
| Agent | Domain | Model | When to Use |
|-------|--------|-------|-------------|
| `systems-designer` | Systems design | Sonnet | Specific mechanic implementation, formula design, loops |
| `level-designer` | Level design | Sonnet | Level layouts, pacing, encounter design, flow |
| `economy-designer` | Economy/balance | Sonnet | Resource economies, loot tables, progression curves |
| `gameplay-programmer` | Gameplay code | Sonnet | Feature implementation, gameplay systems code |
| `engine-programmer` | Engine systems | Sonnet | Core engine, rendering, physics, memory management |
| `ai-programmer` | AI systems | Sonnet | Behavior trees, pathfinding, NPC logic, state machines |
| `network-programmer` | Networking | Sonnet | Netcode, replication, lag compensation, matchmaking |
| `tools-programmer` | Dev tools | Sonnet | Editor extensions, pipeline tools, debug utilities |
| `ui-programmer` | UI implementation | Sonnet | UI framework, screens, widgets, data binding |
| `technical-artist` | Tech art | Sonnet | Shaders, VFX, optimization, art pipeline tools |
| `sound-designer` | Sound design | Haiku | SFX design docs, audio event lists, mixing notes |
| `writer` | Dialogue/lore | Sonnet | Dialogue writing, lore entries, item descriptions |
| `world-builder` | World/lore design | Sonnet | World rules, faction design, history, geography |
| `qa-tester` | Test execution | Haiku | Writing test cases, bug reports, test checklists |
| `performance-analyst` | Performance | Sonnet | Profiling, optimization recs, memory analysis |
| `devops-engineer` | Build/deploy | Haiku | CI/CD, build scripts, version control workflow |
| `analytics-engineer` | Telemetry | Sonnet | Event tracking, dashboards, A/B test design |
| `ux-designer` | UX flows | Sonnet | User flows, wireframes, accessibility, input handling |
| `prototyper` | Rapid prototyping | Sonnet | Throwaway prototypes, mechanic testing, feasibility validation |
| `security-engineer` | Security | Sonnet | Anti-cheat, exploit prevention, save encryption, network security |
| `accessibility-specialist` | Accessibility | Haiku | WCAG compliance, colorblind modes, remapping, text scaling |
| `live-ops-designer` | Live operations | Sonnet | Seasons, events, battle passes, retention, live economy |
| `community-manager` | Community | Haiku | Patch notes, player feedback, crisis comms, community health |
| `cyberneticist` | Systems dynamics | Sonnet | Resource flow topology, cybernetic feedback loops, nonlinear coupling, game theory equilibria |
| `phenomenologist` | Narrative/aesthetic direction | Sonnet | Anti-plasticity narrative, existential texture, cross-species phenomenology, tonal guardianship |
| `deconstructor` | Design stress-testing | Sonnet | Dominant strategy detection, boredom loop analysis, ludonarrative consistency audit, exploit hunting |

## Engine-Specific Agents (use the set matching your engine)

### Engine Leads

| Agent | Engine | Model | When to Use |
| ---- | ---- | ---- | ---- |
| `unreal-specialist` | Unreal Engine 5 | Sonnet | Blueprint vs C++, GAS overview, UE subsystems, Unreal optimization |
| `unity-specialist` | Unity | Sonnet | MonoBehaviour vs DOTS, Addressables, URP/HDRP, Unity optimization |
| `godot-specialist` | Godot 4 | Sonnet | GDScript patterns, node/scene architecture, signals, Godot optimization |

### Unreal Engine Sub-Specialists

| Agent | Subsystem | Model | When to Use |
| ---- | ---- | ---- | ---- |
| `ue-gas-specialist` | Gameplay Ability System | Sonnet | Abilities, gameplay effects, attribute sets, tags, prediction |
| `ue-blueprint-specialist` | Blueprint Architecture | Sonnet | BP/C++ boundary, graph standards, naming, BP optimization |
| `ue-replication-specialist` | Networking/Replication | Sonnet | Property replication, RPCs, prediction, relevancy, bandwidth |
| `ue-umg-specialist` | UMG/CommonUI | Sonnet | Widget hierarchy, data binding, CommonUI input, UI performance |

### Unity Sub-Specialists

| Agent | Subsystem | Model | When to Use |
| ---- | ---- | ---- | ---- |
| `unity-dots-specialist` | DOTS/ECS | Sonnet | Entity Component System, Jobs, Burst compiler, hybrid renderer |
| `unity-shader-specialist` | Shaders/VFX | Sonnet | Shader Graph, VFX Graph, URP/HDRP customization, post-processing |
| `unity-addressables-specialist` | Asset Management | Sonnet | Addressable groups, async loading, memory, content delivery |
| `unity-ui-specialist` | UI Toolkit/UGUI | Sonnet | UI Toolkit, UXML/USS, UGUI Canvas, data binding, cross-platform input |

### Godot Sub-Specialists

| Agent | Subsystem | Model | When to Use |
| ---- | ---- | ---- | ---- |
| `godot-gdscript-specialist` | GDScript | Sonnet | Static typing, design patterns, signals, coroutines, GDScript performance |
| `godot-shader-specialist` | Shaders/Rendering | Sonnet | Godot shading language, visual shaders, particles, post-processing |
| `godot-gdextension-specialist` | GDExtension | Sonnet | C++/Rust bindings, native performance, custom nodes, build systems |
| `structural-architect` | Scene architecture | Sonnet | .tscn tree design, signal contracts, state machine blueprints, script responsibility boundaries |
| `gdscript-geek` | Math/physics implementation | Sonnet | Vector math, curve interpolation, physics API, statically-typed GDScript, guard clauses |
| `ci-judge` | CI enforcement | Sonnet | Godot headless testing, stderr parsing, error classification (structural vs implementation), 3-strike retry gate |
| `router` | Dispatch | Sonnet | Input classification, pipeline routing, auto-handoff orchestration — never does creative work |

## Design Collaboration Triangle

The `cyberneticist`, `phenomenologist`, and `deconstructor` form a design feedback loop:

```
cyberneticist ──(designs systems)──→ phenomenologist
                                      │
                              (narrative constrains systems)
                                      │
                                      ▼
                              deconstructor
                                      │
                        (finds exploits, boring loops,
                         ludonarrative dissonance)
                                      │
                                      ▼
                              cyberneticist + phenomenologist
                              (iterate and re-submit)
```

- **Cyberneticist → Phenomenologist**: Systems output defines the material conditions of the world (scarcity, danger, rhythm of survival). Phenomenologist translates these into felt experience.
- **Phenomenologist → Deconstructor**: Narrative direction sets tone constraints. Deconstructor checks whether the tone survives contact with mechanics.
- **Deconstructor → Cyberneticist + Phenomenologist**: Stress-test results force refinement of both systems and narrative. The loop repeats until Deconstructor returns PASS or CONCERNS (not REJECT).

To invoke all three for a design review:

```
Spawn cyberneticist, phenomenologist, deconstructor in parallel.
After all return: if deconstructor REJECTs, iterate. Otherwise proceed.
```

## Implementation Pipeline (Architect → Geek → Judge)

The `structural-architect`, `gdscript-geek`, and `ci-judge` form a write → enforce → gate loop:

```
structural-architect ──(scene tree + signal contracts + state machines)──→ gdscript-geek
                                                                                │
                                                              (implements functions per spec)
                                                                                │
                                                                                ▼
                                                                           ci-judge
                                                                                │
                                                            (runs godot --headless, parses stderr)
                                                            (STRUCTURAL error → architect rewrites)
                                                            (IMPLEMENTATION error → geek rewrites)
                                                                                │
                                                                                ▼
                                                                     PASS → merge allowed
                                                                     REJECT → loop back
                                                                     BLOCKED(3x) → human escalation
```

- **Structural Architect → GDScript Geek**: Architect outputs Architecture Specification (scene tree, signal contract, state machine, responsibility boundary). Geek implements only the functions specified. Geek never changes architecture.
- **GDScript Geek → CI/CD Judge**: Geek commits code. Judge runs `godot --headless --script tests/run_all.gd`, captures stderr, classifies every error.
- **CI/CD Judge → Architect or Geek**: 
  - `NODE_NOT_FOUND`, `SIGNAL_MISMATCH`, `SCENE_LOAD_FAILURE` → REJECT to Architect
  - `SYNTAX`, `TYPE_MISMATCH`, `DIV_BY_ZERO`, `MATH_DOMAIN` → REJECT to Geek
  - PASS: console clean, no warnings → unblock merge
  - BLOCKED: same error 3 times → escalate to user

### Judge error classification quick reference:

| stderr pattern | Owner | Type |
|---|---|---|
| `Node not found: "..."` | Architect | NODE_NOT_FOUND |
| `signal '...' to nonexistent method` | Architect | SIGNAL_MISMATCH |
| `Scene '...' failed to instantiate` | Architect | SCENE_LOAD_FAILURE |
| `Parser Error:` | Geek | SYNTAX |
| `TypeError:` | Geek | TYPE_MISMATCH |
| `Division by zero` | Geek | DIV_BY_ZERO |
| `Index out of bounds` | Geek | INDEX_BOUNDS |
| `assert() failed` | Geek | ASSERT_FAILED |

### CI script location: `tools/ci_runner.py` (maintained by ci-judge)

## Master Dispatch Architecture

The `router` agent sits at the entry point of every user request. It classifies input and routes to one of two pipelines:

```
                          USER INPUT
                              │
                              ▼
                          ┌─────────┐
                          │  ROUTER │  ← 分类 + 路由 + 编排
                          └────┬────┘
                               │
               ┌───────────────┴───────────────┐
               │                               │
               ▼                               ▼
    ┌──────────────────┐            ┌──────────────────────┐
    │  DESIGN TRIANGLE │            │ IMPLEMENTATION PIPE  │
    │   (Pipeline A)   │            │    (Pipeline B)      │
    └────────┬─────────┘            └──────────┬───────────┘
             │                                 │
    ┌────────┴────────┐              ┌─────────┴──────────┐
    │ cyberneticist   │              │ structural-architect│
    │   (系统设计)     │              │   (场景树/信号/状态) │
    └────────┬────────┘              └─────────┬──────────┘
             │ auto                            │ auto
             ▼                                 ▼
    ┌────────┴────────┐              ┌─────────┴──────────┐
    │ phenomenologist │              │   gdscript-geek    │
    │  (叙事/世界观)   │              │ (数学/物理/GDScript)│
    └────────┬────────┘              └─────────┬──────────┘
             │ auto                            │ auto
             ▼                                 ▼
    ┌────────┴────────┐              ┌─────────┴──────────┐
    │  deconstructor  │              │     ci-judge       │
    │   (审查/裁决)    │              │   (CI自动化法官)    │
    └────────┬────────┘              └─────────┬──────────┘
             │                                 │
      REJECT → loop back              REJECT → loop back
      PASS → can enter Pipeline B     PASS → done
             │                                 │
             └───────────┬─────────────────────┘
                         │
                         ▼
                  HYBRID PIPELINE
              (Design → Architecture → Code → CI)
```

### Auto-Handoff Rules Summary

| Agent | On Complete → Auto Spawn |
|---|---|
| `router` | primary agent (cyberneticist / phenomenologist / structural-architect / gdscript-geek / ci-judge) |
| `cyberneticist` | `phenomenologist` (if narrative needed) or `deconstructor` |
| `phenomenologist` | `cyberneticist` (if system needed) or `deconstructor` |
| `deconstructor` | REJECT→back to origin; PASS→`structural-architect` (if implementing) |
| `structural-architect` | `gdscript-geek` (always) |
| `gdscript-geek` | `ci-judge` (always) |
| `ci-judge` | REJECT-STRUCTURAL→`structural-architect`; REJECT-IMPLEMENTATION→`gdscript-geek`; PASS→done |

### BLOCKED Escalation

Any agent that receives the same error 3 times from CI Judge or Deconstructor stops the pipeline and escalates to the user. No infinite retry loops.
