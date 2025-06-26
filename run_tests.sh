#!/bin/bash

echo "🧪 Running Forkly Unit Tests..."

# Navigate to the project directory
cd "$(dirname "$0")"

# Close Xcode if it's open
echo "📱 Closing Xcode if it's open..."
osascript -e 'tell application "Xcode" to quit'
sleep 2

# Run the tests
echo "🧪 Running tests..."
xcodebuild test -project Forkly-v2.xcodeproj -scheme "Forkly-v2" -destination "platform=iOS Simulator,name=iPhone 16" | xcpretty

# Check the exit code
if [ $? -eq 0 ]; then
    echo "✅ All tests passed!"
else
    echo "❌ Some tests failed. Check the output above for details."
fi 