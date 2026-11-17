#!/usr/bin/env bash
# Runs the GdUnit4 tests in tests/ without opening a window.
# Usage: GODOT_BIN=/path/to/godot ./run_tests.sh [extra GdUnit4 options]
set -u
cd "$(dirname "$0")"
if [ -z "${GODOT_BIN:-}" ]; then
	echo "Set GODOT_BIN to the Godot 4 executable, e.g.:"
	echo "  GODOT_BIN=/path/to/godot ./run_tests.sh"
	exit 1
fi
# Make sure the class cache knows the test and addon scripts.
"$GODOT_BIN" --headless --path . --import > /dev/null 2>&1
"$GODOT_BIN" --headless --path . -s -d --remote-debug tcp://127.0.0.1:0 \
	res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode -c "$@"
exit_code=$?
"$GODOT_BIN" --headless --path . --quiet -s res://addons/gdUnit4/bin/GdUnitCopyLog.gd > /dev/null 2>&1
exit $exit_code
