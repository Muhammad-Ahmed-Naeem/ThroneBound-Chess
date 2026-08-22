class_name StockfishEngine
extends Node

signal bestmove_received(move_str: String)
signal engine_error(msg: String)
signal engine_ready()

var _pid: int = -1
var _stdio: FileAccess
var _stderr: FileAccess
var _thread: Thread
var _running: bool = false
var _is_ready: bool = false

func start_engine() -> bool:
	var os_name = OS.get_name()
	var exe_name = "stockfish.exe" if os_name == "Windows" else "stockfish"
	var path = "res://assets/bin/stockfish/" + exe_name
	var global_path = ProjectSettings.globalize_path(path)
	
	if not FileAccess.file_exists(global_path):
		var msg = "Stockfish executable not found at: " + global_path
		printerr(msg)
		engine_error.emit(msg)
		return false
		
	var result = OS.execute_with_pipe(global_path, [])
	if result.is_empty() or not result.has("stdio"):
		var msg = "Failed to start Stockfish process."
		printerr(msg)
		engine_error.emit(msg)
		return false
		
	_stdio = result["stdio"]
	_stderr = result["stderr"]
	_pid = result["pid"]
	
	_running = true
	_thread = Thread.new()
	_thread.start(_read_loop)
	
	send_command("uci")
	return true

func stop_engine() -> void:
	if _running:
		send_command("quit")
		_running = false
		if _thread and _thread.is_alive():
			_thread.wait_to_finish()
			
	if _pid != -1:
		# Process should terminate gracefully via quit, but fallback to OS.kill if needed
		# In Godot 4, we don't have OS.kill directly for PIDs from execute_with_pipe?
		# Actually, OS.kill(pid) exists in Godot 4
		OS.kill(_pid)
		_pid = -1

func _exit_tree() -> void:
	stop_engine()

func send_command(cmd: String) -> void:
	if _stdio and _stdio.is_open():
		_stdio.store_line(cmd)
		_stdio.flush()

func _read_loop() -> void:
	while _running and _stdio and _stdio.is_open():
		if _stdio.get_error() != OK:
			break
			
		var line = _stdio.get_line().strip_edges()
		if line == "":
			OS.delay_msec(10)
			continue
			
		call_deferred("_handle_output", line)

func _handle_output(line: String) -> void:
	#print("Stockfish: ", line) # Uncomment for debug
	
	if line == "uciok":
		send_command("isready")
	elif line == "readyok":
		_is_ready = true
		engine_ready.emit()
	elif line.begins_with("bestmove "):
		var parts = line.split(" ")
		if parts.size() >= 2:
			var bestmove = parts[1]
			# If bestmove is (none), the game is over
			if bestmove != "(none)":
				bestmove_received.emit(bestmove)
