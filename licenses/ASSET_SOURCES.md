# Thronebound Chess — Asset Sources & Licenses

## Milestone 12 — Signature Combat System Audio Assets

---

### 1. Kenney Impact Sounds

**Asset:** Impact Sounds  
**Creator:** Kenney (Kenney.nl)  
**Source URL:** https://kenney.nl/assets/impact-sounds  
**License:** CC0 1.0 Universal (Public Domain Dedication)  
**Commercial use permitted:** Yes — fully public domain, no restrictions  
**Attribution required:** No (attribution appreciated but not required)  
**Modification permitted:** Yes  
**Redistribution requirements:** None  

**Files used from this pack:**

| Project Filename | Original Filename | Purpose |
|-----------------|------------------|---------|
| `sword_impact.ogg` | `impactMetal_heavy_000.ogg` | Queen/King sword contact |
| `spear_thrust.ogg` | `impactPunch_heavy_000.ogg` | Pawn spear thrust contact |
| `arrow_impact.ogg` | `impactWood_heavy_000.ogg` | Rook projectile impact |
| `horse_charge.ogg` | `footstep_wood_000.ogg` | Knight charge sound |
| `spell_impact.ogg` | `impactBell_heavy_000.ogg` | Bishop magical impact |

**Download date:** 2026-09-03  

---

### 2. Kenney RPG Audio

**Asset:** RPG Audio  
**Creator:** Kenney (Kenney.nl)  
**Source URL:** https://kenney.nl/assets/rpg-audio  
**License:** CC0 1.0 Universal (Public Domain Dedication)  
**Commercial use permitted:** Yes — fully public domain, no restrictions  
**Attribution required:** No (attribution appreciated but not required)  
**Modification permitted:** Yes  
**Redistribution requirements:** None  

**Files used from this pack:**

| Project Filename | Original Filename | Purpose |
|-----------------|------------------|---------|
| `sword_swing.ogg` | `knifeSlice.ogg` | Queen/King sword swing |
| `arrow_launch.ogg` | `drawKnife1.ogg` | Rook projectile launch |
| `spell_cast.ogg` | `metalClick.ogg` | Bishop spell cast charge |

**Download date:** 2026-09-03  

---

### 3. Chess Set 3D Model (Pre-existing, Milestone 8)

**Asset:** Chess Set  
**Creator:** Tomas Dvorak (Sketchfab: Tomas_Dvorak)  
**Source URL:** https://sketchfab.com/3d-models/chess-set-df8d1bd2836a42718c2212fbe93702fb  
**License:** Sketchfab Standard License  
**Commercial use permitted:** Yes — "use worldwide, on all types of media, commercially or not, and in all types of derivative works"  
**Attribution required:** Per Sketchfab Standard terms  
**Where used:** `res://assets/models/pieces/scene.gltf`  

---

## Audio Events Not Yet Covered by External Assets

The following audio events fall back gracefully to existing sounds or silence:

| Event | Fallback | Notes |
|-------|----------|-------|
| `spell_cast` | `capture_impact.wav` | metalClick.ogg deployed for actual cast |
| `horse_charge` | `movement.wav` | footstep_wood.ogg deployed for actual use |

All audio loading uses `_safe_load()` with graceful null fallback — a missing file never crashes or breaks a capture sequence.

---

### 4. OpenGameArt Sword Sounds

**Asset:** 20 Sword Sound Effects (Attacks and Clashes)  
**Creator:** starninjas  
**Source URL:** https://opengameart.org/content/20-sword-sound-effects-attacks-and-clashes  
**License:** CC0 1.0 Universal (Public Domain Dedication)  
**Commercial use permitted:** Yes — fully public domain, no restrictions  
**Attribution required:** No (attribution appreciated but not required)  
**Modification permitted:** Yes  
**Redistribution requirements:** None  

**Files used from this pack:**

| Project Filename | Original Filename | Purpose |
|-----------------|------------------|---------|
| `defeat_clash.ogg` | `sword_clash.1.ogg` | Sharp, realistic sword clash when any piece is defeated |
