#!/usr/bin/env bash
# Install the GitHub Project + Claude Code workflow into the current repo.
#
# Usage (from your project root):
#   curl -fsSL https://raw.githubusercontent.com/carlwestman/gh-project-workflow/main/install.sh | bash
#
# Or if you've cloned the repo:
#   ./install.sh /path/to/your/project

set -eo pipefail

TARGET_DIR="${1:-.}"
SOURCE_REPO="https://raw.githubusercontent.com/carlwestman/gh-project-workflow/main"

# Detect if running locally (./install.sh) or piped (curl | bash)
SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "bash" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

echo "📦 Installing GitHub Project workflow into: $(cd "$TARGET_DIR" && pwd)"
echo ""

# ─── Helper: download from repo (flat) and place in target (nested) ──────────
# Usage: install_file <repo_filename> <target_path>

install_file() {
  local repo_file="$1"
  local target_path="$2"
  local target="$TARGET_DIR/$target_path"
  local target_dir
  target_dir=$(dirname "$target")

  mkdir -p "$target_dir"

  if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/$repo_file" ]]; then
    # Local install (cloned repo)
    cp "$SCRIPT_DIR/$repo_file" "$target"
  else
    # Remote install (curl | bash)
    if ! curl -fsSL "$SOURCE_REPO/$repo_file" -o "$target"; then
      echo "  ❌ Failed to download $repo_file — is the repo pushed to GitHub?" >&2
      return 1
    fi
  fi

  echo "  ✅ $target_path"
}

# ─── Check for existing files ────────────────────────────────────────────────

check_conflict() {
  local target_path="$1"
  if [[ -f "$TARGET_DIR/$target_path" ]]; then
    echo "  ⚠️  $target_path already exists — skipping (delete it first to overwrite)"
    return 1
  fi
  return 0
}

# ─── Install files ───────────────────────────────────────────────────────────

echo "Installing files..."

# Helper script (always overwrite — it's the core tool)
install_file "gh-project.sh" "scripts/gh-project.sh"
chmod +x "$TARGET_DIR/scripts/gh-project.sh"

# Slash commands (skip if they already exist — user may have customised)
for cmd in next-issue review-ready update-progress board; do
  if check_conflict ".claude/commands/$cmd.md"; then
    install_file "$cmd.md" ".claude/commands/$cmd.md"
  fi
done

# GitHub Action (skip if exists)
if check_conflict ".github/workflows/issue-done-on-merge.yml"; then
  install_file "issue-done-on-merge.yml" ".github/workflows/issue-done-on-merge.yml"
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