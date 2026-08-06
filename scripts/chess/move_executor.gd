class_name MoveExecutor
extends RefCounted

class UndoRecord:
	var move: ChessMove
	var original_moving_piece: ChessPiece
	var original_captured_piece: ChessPiece
	var original_from_pos: Vector2i
	var original_to_pos: Vector2i

# Permanently execute a move on the board
func execute_move(board: BoardState, move: ChessMove) -> void:
	board.remove_piece(move.from_position)
	if move.captured_piece != null:
		board.remove_piece(move.to_position)
	board.set_piece(move.to_position, move.moving_piece)

# Simulates a move, returning an undo record to completely restore the previous state
func simulate_move(board: BoardState, move: ChessMove) -> UndoRecord:
	var record = UndoRecord.new()
	record.move = move
	record.original_moving_piece = move.moving_piece
	record.original_captured_piece = move.captured_piece
	record.original_from_pos = move.from_position
	record.original_to_pos = move.to_position
	
	execute_move(board, move)
	return record

# Completely restores the board to its pre-simulated state
func restore_move(board: BoardState, record: UndoRecord) -> void:
	# Pull the moving piece back to origin
	board.remove_piece(record.original_to_pos)
	board.set_piece(record.original_from_pos, record.original_moving_piece)
	
	# Replace captured piece if there was one
	if record.original_captured_piece != null:
		board.set_piece(record.original_to_pos, record.original_captured_piece)
