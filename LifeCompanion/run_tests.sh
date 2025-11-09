#!/bin/bash

# LifeCompanion Unit Tests Runner
# Usage: ./run_tests.sh [test_name]

set -e

PROJECT_PATH="/Users/gayeugur/Desktop/git/LifeCompanion/LifeCompanion"
SCHEME="LifeCompanion"
DESTINATION="platform=iOS Simulator,name=iPhone 15,OS=latest"

echo "🧪 LifeCompanion Unit Tests"
echo "=========================="

cd "$PROJECT_PATH"

if [ -n "$1" ]; then
    echo "Running specific test: $1"
    xcodebuild test \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -only-testing:"LifeCompanionTests/$1" \
        | xcpretty --test --color
else
    echo "Running all tests..."
    xcodebuild test \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        | xcpretty --test --color
fi

echo ""
echo "✅ Test run completed!"