@echo off
set GODOT="C:\Users\great\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe"
echo Running tests...
%GODOT% --headless -s tests\test_board_state.gd
%GODOT% --headless -s tests\test_move_generator.gd
%GODOT% --headless -s tests\test_move_execution.gd
%GODOT% --headless -s tests\test_chess_rules.gd
%GODOT% --headless -s tests\test_special_moves.gd
%GODOT% --headless -s tests\test_game_endings.gd
%GODOT% --headless -s tests\test_draw_rules.gd
%GODOT% --headless -s tests\test_chess_game.gd
%GODOT% --headless -s tests\test_fen_generator.gd
%GODOT% --headless -s tests\test_stockfish_adapter.gd
%GODOT% --headless -s tests\test_captured_hud.gd
echo Done.
