# Thronebound Chess — Project Architecture & Development Constitution

## 1. Core Philosophy
- **Chess Determines What Happens:** The underlying game is 100% traditional chess.
- **Presentation Determines How It Looks:** Unique identity is driven solely by visual, audio, and animation presentation.
- **Strict Separation of Concerns:** Chess rules system MUST NOT depend on animations, VFX, audio, cameras, models, environments, or UI.
- **No RPG Mechanics:** No HP, damage systems, stats, skills, progression, equipment, loot, XP, or custom chess rules.

## 2. Character & Combat Identity
- **Pawn:** Infantry soldier (spear and shield). Grounded, short spear attack.
- **Knight:** Mounted warrior. Charging attack.
- **Bishop:** Magical priest. Ranged magical projectile.
- **Rook:** Fortified ranged unit. Physical arrows/projectiles (not humanoid).
- **Queen:** Warrior queen. Sword-based combat.
- **King:** Emperor. Dignified, restrained sword attack.
- **Captures:** Short, stylized sequences (0.6–1.2s). NOT lengthy cinematics. Must use a modular, data-driven system (no hardcoded attacker/defender animation pairs).

## 3. High-Level Architecture
- **Chess Core:** `BoardState`, `Piece`, `Move`, `MoveGenerator`, `ChessRules`, `TurnManager`, `GameState`, `GameResult`, `PromotionSystem`
- **Presentation:** `PieceController`, `BoardView`, `MoveVisualizer`, `MovementAnimator`, `CapturePresentationManager`, `CameraController`, `VFXController`, `AudioController`
- **AI:** `ChessAI`, `StockfishAdapter`
- **Environment:** `EnvironmentManager`, `EnvironmentPreset`
- **UI:** `MainMenu`, `GameSetup`, `GameHUD`, `PauseMenu`, `SettingsMenu`, `GameResultScreen`, `PromotionUI`

*Note: Systems should only be implemented as required by the active development milestone.*

## 4. Coding Principles
- **Prefer:** Small focused scripts, composition, clear naming, typed GDScript, signals/events, data-driven configuration, minimal coupling.
- **Avoid:** Giant GameManager scripts, global mutable state, duplicated chess logic, hardcoded presentation logic inside the chess engine, mixing UI/animation code with rules, unnecessary singletons/abstractions.

## 5. Development & AI Rules
1. Implement one coherent feature at a time (no giant single-step implementations).
2. Keep changes localized; do not rewrite unrelated systems.
3. Preserve existing functionality unless explicitly tasked to change it.
4. Document significant architectural decisions in comments.
5. Ensure the project continues to run successfully after each milestone.
6. Prefer simple implementations over clever ones.

## 6. Project Scope & Targets
- **Target:** 60 FPS on Windows PC (primary platform).
- **Camera/Environment:** 3-quarter top-down camera in an atmospheric Throne Room.
- **Assets:** $0 budget (Mixamo, Blender, Godot procedural animation, free licensed audio/VFX). Log all licenses in `res://licenses/`.
- **MVP Features:** Standard chess, 3D board, 6 piece types, movement & capture presentation, Throne Room, Stockfish AI, local multiplayer, basic UI/audio/VFX.
- **Out of Scope for MVP:** Online multiplayer, ranked, leaderboards, any RPG systems, console support, complex cinematics.

## 7. Milestone 1: Chess Core Foundation
- **Coordinate Convention:** Represented via `Vector2i(file, rank)`, where `file` is `0–7` (a-h) and `rank` is `0–7` (1-8).
- **Piece Representation:** Type-safe enums (`ChessTypes.PieceType`, `ChessTypes.PieceColor`). Stored in a lightweight `ChessPiece` data representation independent of presentation.
- **BoardState Responsibility:** Manages the active pieces on a 1D 64-element array backing the 8x8 board. Handles initialization of the standard chess position, placing, retrieving, and removing pieces.
- **Currently Supported:** Empty board representation, valid piece configuration, specific positions, bounds checking, and test script verification (`test_board_state.gd`).
- **Intentionally Excluded:** Legal move generation, captures, check/checkmate logic, castling, en passant, promotion, presentation, AI, UI, and multiplayer.
