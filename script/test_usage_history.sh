#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_BINARY="$(mktemp /tmp/liveprompt-history.XXXXXX)"
trap 'rm -f "$TEST_BINARY"' EXIT
swiftc "$ROOT_DIR/Sources/LivePrompt/Models/UsageHistoryStore.swift" "$ROOT_DIR/script/test_usage_history.swift" -o "$TEST_BINARY"
"$TEST_BINARY"
