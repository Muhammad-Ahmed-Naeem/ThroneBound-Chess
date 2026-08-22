extends Control

@onready var title_label = $CenterContainer/VBoxContainer/TitleLabel
@onready var subtitle_label = $CenterContainer/VBoxContainer/SubtitleLabel
@onready var rematch_button = $CenterContainer/VBoxContainer/MarginContainer/RematchButton
@onready var main_menu_button = $CenterContainer/VBoxContainer/MainMenuButton

signal rematch_requested
signal main_menu_requested

func _ready() -> void:
	rematch_button.pressed.connect(func(): rematch_requested.emit())
	main_menu_button.pressed.connect(func(): main_menu_requested.emit())
	hide()

func display_result(result: int, winner: int = -1) -> void:
	show()
	rematch_button.grab_focus()
	
	match result:
		ChessTypes.GameResult.CHECKMATE:
			title_label.text = "CHECKMATE"
			subtitle_label.text = "WHITE WINS" if winner == ChessTypes.PieceColor.WHITE else "BLACK WINS"
		ChessTypes.GameResult.STALEMATE:
			title_label.text = "STALEMATE"
			subtitle_label.text = "DRAW"
		ChessTypes.GameResult.DRAW_INSUFFICIENT_MATERIAL:
			title_label.text = "DRAW"
			subtitle_label.text = "INSUFFICIENT MATERIAL"
		ChessTypes.GameResult.DRAW_THREEFOLD_REPETITION:
			title_label.text = "DRAW"
			subtitle_label.text = "THREEFOLD REPETITION"
		ChessTypes.GameResult.DRAW_FIFTY_MOVE:
			title_label.text = "DRAW"
			subtitle_label.text = "FIFTY-MOVE RULE"
		_:
			title_label.text = "GAME OVER"
			subtitle_label.text = ""

func hide_result() -> void:
	hide()
