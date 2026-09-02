#!/bin/bash
#
# recover-device-feedback.sh
#
# Pulls EmberWatch feedback from a connected iOS device and decodes the UserDefaults entry.
# Requires: Mac with Xcode 15+ and the device plugged in via USB or Wi-Fi sync.
#
# Usage:
#   ./scripts/recover-device-feedback.sh
#

set -e

DEVICE_UDID="00008150-0010156221BA401C"
BUNDLE_ID="com.ember.watch"
PREF_KEY="emberFeedbackEntries"
OUTPUT_DIR="/tmp/ember-device-feedback"

echo "📱 EmberWatch Feedback Recovery"
echo "================================"
echo ""
echo "Target device: $DEVICE_UDID"
echo "Bundle ID: $BUNDLE_ID"
echo "Preference key: $PREF_KEY"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Copy device preferences container to local machine
echo "Copying preferences from device..."
xcrun devicectl device copy from \
  --device "$DEVICE_UDID" \
  --domain appPreferences \
  --bundleID "$BUNDLE_ID" \
  "$OUTPUT_DIR"

PLIST_PATH="$OUTPUT_DIR/Library/Preferences/$BUNDLE_ID.plist"

if [ ! -f "$PLIST_PATH" ]; then
  echo "❌ Error: Could not find preferences file at $PLIST_PATH"
  exit 1
fi

echo "✅ Preferences copied to: $PLIST_PATH"
echo ""

# Extract and decode the feedback entries
echo "Extracting feedback entries..."

# Read the binary plist value for the key
plutil -extract "$PREF_KEY" raw -o - "$PLIST_PATH" > "$OUTPUT_DIR/feedback-raw.bin" 2>/dev/null || {
  echo "❌ Error: Key '$PREF_KEY' not found in preferences."
  echo "   The app may not have any saved feedback yet."
  exit 1
}

# The value is JSON-encoded data in binary plist format
# We need to convert it from base64 or hex to JSON
if command -v xxd &> /dev/null; then
  # Try to parse as JSON directly if it's already text
  cat "$OUTPUT_DIR/feedback-raw.bin" | python3 -c "
import sys
import json

try:
    data = sys.stdin.buffer.read()
    # Try to decode as JSON (it's stored as binary data in the plist)
    entries = json.loads(data.decode('utf-8'))
    print(json.dumps(entries, indent=2))
except Exception as e:
    print(f'Error decoding feedback: {e}', file=sys.stderr)
    sys.exit(1)
" > "$OUTPUT_DIR/feedback.json"

  if [ $? -eq 0 ]; then
    echo "✅ Decoded feedback entries saved to: $OUTPUT_DIR/feedback.json"
    echo ""
    echo "Preview:"
    head -n 20 "$OUTPUT_DIR/feedback.json"
  else
    echo "❌ Failed to decode feedback entries."
    echo "   Raw binary data saved to: $OUTPUT_DIR/feedback-raw.bin"
  fi
else
  echo "⚠️  xxd not found. Raw data saved to: $OUTPUT_DIR/feedback-raw.bin"
  echo "   You may need to manually decode the binary plist data."
fi

echo ""
echo "📂 All files saved to: $OUTPUT_DIR"
