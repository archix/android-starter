#!/usr/bin/env bash
set -euo pipefail

HOOK_DIR="$(git rev-parse --show-toplevel)/.git/hooks"

cat > "$HOOK_DIR/pre-commit" << 'HOOK'
#!/usr/bin/env bash
set -euo pipefail

echo "Running ktlintCheck..."
if ! ./gradlew ktlintCheck --daemon; then
    echo ""
    echo "ktlintCheck failed. Run ./gradlew ktlintFormat to auto-fix style issues."
    exit 1
fi
HOOK

chmod +x "$HOOK_DIR/pre-commit"
echo "pre-commit hook installed successfully."
