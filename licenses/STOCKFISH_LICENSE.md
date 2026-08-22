# Stockfish License

Thronebound Chess uses **Stockfish** as its AI engine. 

**Source:** https://stockfishchess.org/
**License:** GNU General Public License v3.0 (GPLv3)

## Important Note Regarding Licensing
The Thronebound Chess engine and source code itself is NOT GPL-licensed merely by its interaction with Stockfish. Stockfish is invoked as a completely separate executable via standard input/output streams (Universal Chess Interface - UCI protocol) using the `OS.execute_with_pipe()` function. This architecture constitutes communicating at arm's length with an independent process, rather than linking or derivative integration. 

Should you choose to distribute Thronebound Chess with the compiled `stockfish.exe` binary included in the `assets/bin/stockfish/` directory, the distribution of that specific binary must comply with the GPLv3 terms (e.g., providing source code or a written offer for the source code of Stockfish).
