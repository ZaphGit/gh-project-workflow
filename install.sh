#!/usr/bin/env bash
# Install the GitHub Project + Claude Code workflow into the current repo.
#
# Usage (from your project root):
#   curl -fsSL https://raw.githubusercontent.com/carlwestman/gh-project-workflow/main/install.sh | bash
#
# Or if you've cloned the repo:
#   ./install.sh /path/to/your/project

set -euo pipefail

TARGET_DIR="${1:-.}"
SOURCE_REPO="https://raw.githubusercontent.com/carlwestman/gh-project-workflow/main"

# If running via curl/pipe, we fetch from GitHub
# If running locally, we copy from the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📦 Installing GitHub Project workflow into: $(cd "$TARGET_DIR" && pwd)"
echo ""

# ─── Helper: fetch or copy a file ────────────────────────────────────────────

install_file() {
  local rel_path="$1"
  local target="$TARGET_DIR/$rel_path"
  local target_dir
  target_dir=$(dirname "$target")

  mkdir -p "$target_dir"

  if [[ -f "$SCRIPT_DIR/$rel_path" ]]; then
    # Local install
    cp "$SCRIPT_DIR/$rel_path" "$target"
  else
    # Remote install
    curl -fsSL "$SOURCE_REPO/$rel_path" -o "$target"
  fi

  echo "  ✅ $rel_path"
}

# ─── Check for existing files ────────────────────────────────────────────────

check_conflict() {
  local rel_path="$1"
  if [[ -f "$TARGET_DIR/$rel_path" ]]; then
    echo "  ⚠️  $rel_path already exists — skipping (delete it first to overwrite)"
    return 1
  fi
  return 0
}

# ─── Install files ───────────────────────────────────────────────────────────

echo "Installing files..."

# Helper script (always overwrite — it's the core tool)
install_file "scripts/gh-project.sh"
chmod +x "$TARGET_DIR/scripts/gh-project.sh"

# Slash commands (skip if they already exist — user may have customised)
for cmd in next-issue review-ready update-progress board; do
  if check_conflict ".claude/commands/$cmd.md"; then
    install_file ".claude/commands/$cmd.md"
  fi
done

# GitHub Action (skip if exists)
if check_conflict ".github/workflows/issue-done-on-merge.yml"; then
  install_file ".github/workflows/issue-done-on-merge.yml"
fi

# ─── Update .gitignore ──────────────────────────────────────────────────────

if [[ -f "$TARGET_DIR/.gitignore" ]]; then
  if ! grep -qF ".gh-project.env" "$TARGET_DIR/.gitignore"; then
    echo ".gh-project.env" >> "$TARGET_DIR/.gitignore"
    echo "  ✅ Added .gh-project.env to .gitignore"
  else
    echo "  ℹ️  .gh-project.env already in .gitignore"
  fi
else
  echo ".gh-project.env" > "$TARGET_DIR/.gitignore"
  echo "  ✅ Created .gitignore with .gh-project.env"
fi

# ─── Post-install instructions ───────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Next steps:"
echo ""
echo "  1. Run setup (connects to your GitHub Project):"
echo "     ./scripts/gh-project.sh setup"
echo ""
echo "  2. If you get permission errors, grant project scope:"
echo "     gh auth refresh -s project"
echo ""
echo "  3. Set the GitHub Action variable:"
echo "     Repo → Settings → Variables → Actions → Add:"
echo "     PROJECT_NUMBER = <your project number>"
echo ""
echo "  4. Add the workflow docs to your CLAUDE.md:"
echo "     Append the contents of CLAUDE-PROJECT-WORKFLOW.md"
echo "     (or fetch it: curl -fsSL $SOURCE_REPO/CLAUDE-PROJECT-WORKFLOW.md)"
echo ""
echo "  5. Test it:"
echo "     ./scripts/gh-project.sh list-ready"
echo "     # In Claude Code: /board"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
