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

## 8. Milestone 2: Move Representation & Pseudo-Legal Move Generation
- **Move Representation:** `ChessMove` acts purely as an immutable data container describing `from_position`, `to_position`, `moving_piece`, and a nullable `captured_piece`. It does not contain presentation or UI data.
- **MoveGenerator Responsibility:** Generates pseudo-legal moves for any given position using `generate_moves(board, pos)`. It calculates movement according to standard bounds, occupancy, and piece-specific patterns.
- **Immutability:** Move generation strictly reads from `BoardState` and returns an array of `ChessMove`s without mutating the board state.
- **Pseudo-Legal vs Legal:** This tier exclusively computes **pseudo-legal** moves (i.e. physical board movement capability). It strictly avoids check/King-safety detection.
- **Supported Mechanics:** Bounds checking, blocking logic (friendly collision, enemy capture), sliding logic (Bishop, Rook, Queen), jumping (Knight), single step (King), Pawn (forward step, double step from starting rank, diagonal captures).
- **Intentionally Excluded Mechanics:** King-safety filtering, Check/Checkmate, Stalemate, Castling, En passant, Promotion, move execution (state mutation), AI evaluation, and all visual/audio presentation.

## 9. Milestone 3: Move Execution, Turn State & King Safety
- **Move Execution Responsibility:** `MoveExecutor` acts as the sole mutator for the board. It permanently places/removes pieces to reflect a played move.
- **Reversible Simulation:** `simulate_move` returns an opaque `UndoRecord` holding original state. `restore_move` uses it to perfectly rollback the board state without any leakage.
- **Attack Detection:** `ChessRules` independently calculates piece threats against specific squares regardless of legal movement constraints (e.g. independently computing Pawn forward diagonals).
- **Check Detection & King Location:** Consistently maps the King via dynamic lookup (`find_king`) avoiding duplicated state, and verifies if it is threatened via attack detection.
- **Legal Move Filtering:** `ChessRules` encapsulates pseudo-legal generation, simulates every move, flags any move leaving the King under attack (such as exposing pinned pieces), and discards it.
- **Turn Responsibility:** `TurnManager` oversees side ownership and toggling (`WHITE` vs `BLACK`).
- **Intentionally Excluded Rules:** Checkmate, Stalemate, Castling, En passant, Promotion, draw rules, AI, and all presentation/UI systems remain explicitly deferred.
