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

## 10. Milestone 4: Complete Chess Rules
- **Game History:** `GameHistory` tracks contextual variables (Castling rights, En Passant targets, halfmove clock, and position keys). Its `push_state()` and `pop_state()` allow flawlessly reversing mutations during simulation.
- **Special Move Types:** `ChessMove` now encodes `MoveType` (Normal, Castle, En Passant, Promotion) and `promotion_type`.
- **En Passant:** Computed dynamically, matching a valid double-step target logged inside `GameHistory` and clearing properly after one turn.
- **Castling Safety & Rights:** Rights are rigorously enforced and revoked correctly when Kings/Rooks move or are captured. Through-check and in-check limits are tested and explicitly blocked.
- **Promotion:** Safely translates pawns reaching terminal ranks to Queen, Rook, Bishop, or Knight, ensuring simulation cleanly rewinds the morphed `PieceType`.
- **Game Endings:** Implemented strict rule separation to detect Checkmate (in check + 0 legal moves) versus Stalemate (not in check + 0 legal moves).
- **Draw States:** Added explicit methods to verify Automatic Draws via Insufficient Material (K vs K, K+N vs K, K+B vs K) and Claimable Draws (Fifty-move rule via halfmove clock, Threefold Repetition tracking via position hashing). 
- **Intentionally Excluded:** UI overlays, AI logic, 3D presentations, and online networking remain explicitly excluded to maintain headless correctness.

## 11. Milestone 5: Chess Game Flow
- **ChessGame Orchestrator:** Acts as the primary facade joining `BoardState`, `GameHistory`, `TurnManager`, `ChessRules`, and `MoveExecutor`. It provides a high-level API (`try_move`, `get_legal_moves`, `get_game_result`) to drive a match without duplicating internal core logic.
- **MoveResult & GameResult:** `try_move()` returns explicit `MoveResult` values (`SUCCESS`, `GAME_OVER`, `INVALID_SOURCE`, `WRONG_TURN`, `ILLEGAL_MOVE`, `INVALID_PROMOTION`) rather than relying on exceptions. `GameResult` tracks states like `CHECKMATE`, `STALEMATE`, and `DRAW_*` cleanly.
- **Execution Pipeline:** `try_move()` generates purely legal moves internally, validates the requested move via `to_position` and `promotion_type`, invokes `MoveExecutor`, modifies `TurnManager`, records resulting `GameHistory`, and re-evaluates `_evaluate_terminal_state()`.
- **Signal Boundary:** Emits a `move_executed(move: ChessMove)` signal post-success to bridge the core simulation logically cleanly out to the future Presentation Layer.
- **Move History:** A clean array of successfully executed `ChessMove` entries is maintained on the orchestrator, containing pure data representation devoid of presentation bindings.

## 12. Milestone 6: 3D Presentation Foundation
- **Dependency Direction:** The Presentation Layer strictly observes the `ChessGame`. It does not calculate move legality, check status, or draw rules. `Chess Core -> Presentation`.
- **Mathematical Picking:** Uses `Plane(Vector3.UP, 0.0).intersects_ray(origin, normal)` to perform input detection against the mathematical XZ plane instead of utilizing expensive Physics/Collider bodies.
- **BoardView:** Orchestrates the 3D generation of squares and pieces and handles mouse interactions. It intercepts clicks, builds requests, and delegates them to `ChessGame.try_move()`.
- **PieceController:** Manages purely the visual instantiation and mesh updates (e.g. promoting mesh shape). Driven entirely by the `BoardView` synchronizing its list of active logical pieces.
- **MoveVisualizer:** Receives an array of `ChessMove` instances from `ChessGame` when a piece is clicked, and paints flat planes over target squares (green for normal, red for capture) independent of rules engines.
- **Intentionally Deferred:** No animations, complex UI, settings, Stockfish, or polished VFX are added. The goal is technical validation of the core bridge logic.

## 13. Milestone 7: Presentation Smoothness & Visual Feedback
- **Tween-based Movement:** `PieceController` replaces instant translation with mathematical Tween interpolation. It interpolates its logical path over 0.25 seconds.
- **Selection Feedback:** `BoardView` instructs selected pieces to elevate slightly along the Y-axis via Tweening to clearly indicate active selection.
- **Input Locking:** `BoardView` strictly ignores all new `_unhandled_input` while `_is_animating` is true, ensuring rapid or overlapping clicks do not desync the visual interpolations.
- **Capture Response:** Captured pieces undergo a rapid scaling Tween to zero via `Tween.TRANS_BACK` before being freed. A generic response designed solely for prototype clarity.
- **Last Move Highlighting:** Added subtle yellow planes tracking the `from` and `to` positions of the previously executed `ChessMove` to aid logical readability.
- **Synchronization Strategy:** Leveraged Godot's `Signal` pipeline dynamically binding to `move_completed` to await dynamic tween lengths without blocking `ChessGame`'s headless simulation capability.

## 14. Milestone 8: Game-Ready Assets & Combat Visuals
- **Asset Integration:** Successfully imported 3D static meshes for all pieces and board. Integrated them into `PieceController` with procedural scaling to match logical square size.
- **Graveyard System:** Eliminated pieces are no longer freed instantly. They are procedurally animated (tumbled) into neat, organized rows on the left (captured White) and right (captured Black) sides of the board.
- **Capture Presentation:** Added `CapturePresentationManager` as a dedicated orchestration class for captures. It takes control of the attacker and defender pieces and puppets them through a procedural combat sequence ("Hop and Smash") before returning control to the board. 
- **Core Separation:** The manager remains completely isolated from the `ChessGame`. It only reads the visual `PieceController` instances and the `ChessMove`. Input is locked (`_is_animating` via `_animations_pending`) until the sequence finishes, ensuring perfect visual synchronization with the already-advanced logical state.
- **Edge Cases:** Safely handles Promotion (attacker visually updates before combat) and En Passant (finds defender via `move.captured_piece.position` instead of destination square).

## 15. Milestone 9: Environment, VFX & Audio Foundation
- **Procedural Environment:** Introduced `EnvironmentManager` to construct a stylized dark fantasy Throne Room entirely procedurally (using CSG primitives). This avoids heavy textures and external asset dependencies while providing scale and depth.
- **Lighting Strategy:** Employs a `DirectionalLight3D` key light (moonlight) and warm `OmniLight3D` nodes (torchlight) with subtle fog/glow to create atmosphere without compromising the readability of the chess pieces.
- **VFX Integration:** Created `VFXController` to manage procedural generic particle effects (e.g., impact dust/sparks using `GPUParticles3D`). This is directly triggered during the "strike" phase of `CapturePresentationManager`.
- **Audio Architecture:** Built a clean event-driven `AudioController` to manage spatialized sound (`AudioStreamPlayer3D`). It allows transparent injection of `.wav`/`.ogg` files later without altering the presentation calling logic.
- **Strict Separation:** The environment, VFX, and audio presentation systems are completely decoupled from `ChessGame`, `BoardState`, and rules engines, continuing the established project philosophy.

## 16. Milestone 10: Game Shell & UI Flow
- **Architecture Philosophy:** The UI is an outer shell. It observes the Chess Core via `ChessGame` but never calculates chess rules, checkmate conditions, or move legality itself.
- **Scene Flow:** `MainMenu` -> `GameSetup` -> `ChessBoard`. 
- **SceneTransition Autoload:** A minimal autoload (`SceneTransition`) is used exclusively to hold the active `GameConfiguration` and trigger scene swaps. It is intentionally restricted from becoming a global GameManager.
- **UI Components:**
  - `MainMenu`: Application entry point. Handles Play, Settings, Quit.
  - `GameSetup`: Configures the match (e.g. Local 2 Player vs AI). "VS AI" is deliberately visually disabled to prepare for future Stockfish integration without rewriting the UI.
  - `GameHUD`: Minimalist overlay indicating current turn and check state. Displayed within the `ChessBoard` scene.
  - `PauseMenu`: Overlays the match on `ESC`. Safely pauses the `SceneTree` while remaining interactive, preventing rogue input to the `BoardView`.
  - `GameResultScreen`: Appears upon terminal game states (Checkmate/Draw). Evaluates winner purely from `ChessGame` data.
  - `SettingsMenu`: Manages volume (Master, Music, SFX via Godot's audio buses) and window modes. Saves persistently using `ConfigFile` to `user://settings.cfg`.
- **Intentionally Deferred:** Stockfish/AI gameplay, piece-specific signature combat, and online networking remain excluded.

## 17. Milestone 11: Stockfish AI Integration
- **Strict Orchestration Architecture:** AI is cleanly bridged as an external recommender. `ChessGame` remains the absolute sovereign authority over rules, movement validation, check, and board states.
- **AI Subsystem:** 
  - `FenGenerator`: Translates `ChessGame`, `TurnManager`, and `GameHistory` into strict FEN format strings. Handles En Passant targets, Castling validation, and Move clocks natively from history.
  - `StockfishEngine`: Raw process wrapper invoking `assets/bin/stockfish/stockfish.exe` over a background Thread using `OS.execute_with_pipe()`. Deals only with raw UCI string processing, isolating the game loop from blocking input.
  - `StockfishAdapter`: Bridging facade tying `StockfishEngine` to `ChessGame`. Automatically parses `bestmove` strings (like `e7e8q`) back to `Vector2i` endpoints and `PieceType` enums, injecting them into `ChessGame.try_move()`.
- **Presentation Seamlessness:** By routing AI decisions back through `ChessGame.try_move()`, AI moves automatically trigger `move_executed`, meaning AI captures and movements utilize the exact same animation, audio, and VFX systems built for humans without any duplicate code.
- **Graceful Lifecycle Management:** Checks `_is_ai_turn()` and automatically requests moves without human input. Handles headless pauses securely (`stop` search on pause, `go` on resume) and cleans up processes safely when exiting back to the Main Menu. Missing binaries result in a logged error rather than an application crash.
- **Licensing Constraint:** Because Stockfish is GPL-licensed, it communicates strictly over independent external process pipelines. Usage and distribution rules are correctly documented in `licenses/STOCKFISH_LICENSE.md`.
