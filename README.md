# gh-project-workflow

GitHub Projects v2 + Claude Code integration. Manage issues through a Kanban board and let Claude Code pick up, work on, and deliver them — all from slash commands.

## What It Does

```
You prioritise issues in GitHub Projects (drag to reorder)
        │
        ▼
  /next-issue      → picks top Ready item, moves to In Progress, creates branch
  /update-progress → appends status updates to the issue
  /review-ready    → pushes, creates PR, moves to Review
        │
        ▼
  Merge PR to main → GitHub Action auto-moves issue to Done
```

## Quick Install

From any project root:

```bash
curl -fsSL https://raw.githubusercontent.com/carlwestman/gh-project-workflow/main/install.sh | bash
```

Then run setup:

```bash
./scripts/gh-project.sh setup
```

## What Gets Installed

```
your-repo/
├── .claude/commands/
│   ├── next-issue.md        # Pick up next prioritised issue
│   ├── review-ready.md      # Submit work for review
│   ├── update-progress.md   # Update issue with progress
│   └── board.md             # View board status
├── .github/workflows/
│   └── issue-done-on-merge.yml  # Auto-move to Done on merge
└── scripts/
    └── gh-project.sh        # CLI wrapper for Projects v2 GraphQL
```

## Prerequisites

- [`gh` CLI](https://cli.github.com/) installed and authenticated
- [`jq`](https://jqlang.github.io/jq/) installed
- [GitHub Project (v2)](https://docs.github.com/en/issues/planning-and-tracking-with-projects) linked to your repo
- Project board columns: **Backlog** → **Ready** → **In Progress** → **Review** → **Done**

### Installing `gh` CLI

**macOS:**

```bash
brew install gh
```

**Linux (Debian/Ubuntu):**

```bash
(type -p wget >/dev/null || sudo apt install wget -y) \
  && sudo mkdir -p -m 755 /etc/apt/keyrings \
  && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
  && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && sudo apt update \
  && sudo apt install gh -y
```

**Windows:**

```powershell
winget install --id GitHub.cli
```

Then authenticate and grant project scope:

```bash
gh auth login
gh auth refresh -s project
```

### Installing `jq`

**macOS:**

```bash
brew install jq
```

**Linux (Debian/Ubuntu):**

```bash
sudo apt install jq -y
```

**Windows:**

```powershell
winget install --id jqlang.jq
```

## Setup

### 1. Create a GitHub Project

Repo → **Projects** tab → **New project** → **Board** layout.

Add/rename columns to: `Backlog`, `Ready`, `In Progress`, `Review`, `Done`.

### 2. Install the workflow

```bash
curl -fsSL https://raw.githubusercontent.com/carlwestman/gh-project-workflow/main/install.sh | bash
```

### 3. Connect to your project

```bash
./scripts/gh-project.sh setup
```

This auto-detects your repo, finds linked projects, maps column names to GraphQL IDs, and writes `.gh-project.env`.

If you hit permission errors:

```bash
gh auth refresh -s project
```

### 4. Configure the GitHub Action

Repo → **Settings** → **Secrets and variables** → **Actions** → **Variables**:

| Variable | Value |
|---|---|
| `PROJECT_NUMBER` | Your project number (from the URL) |

### 5. Add to your CLAUDE.md

Append the contents of [`CLAUDE-PROJECT-WORKFLOW.md`](./CLAUDE-PROJECT-WORKFLOW.md) to your project's `CLAUDE.md` so Claude Code knows the workflow in every session.

## Usage

### Claude Code Slash Commands

| Command | What it does |
|---|---|
| `/next-issue` | Pick up top Ready issue, move to In Progress, create branch, start working |
| `/review-ready` | Run tests, push, create PR with `Closes #N`, move to Review |
| `/update-progress` | Append progress notes to current issue description |
| `/board` | Show all columns with item counts |

### CLI Commands

```bash
./scripts/gh-project.sh next                    # Show top Ready item
./scripts/gh-project.sh list-ready               # List all Ready items
./scripts/gh-project.sh list-in-progress          # List In Progress items
./scripts/gh-project.sh list "Review"             # List any column by name
./scripts/gh-project.sh move 42 "In Progress"     # Move issue to column
./scripts/gh-project.sh assign 42                 # Assign issue to yourself
```

## How Prioritisation Works

The order of items in the Ready column is determined by their position in the GitHub Project board. Drag items up/down in the board UI to set priority. `/next-issue` always picks the top item.

## Customising

**Column names** — The setup script does fuzzy matching (`ready`, `in progress`, `review`, `done`). If your columns are named differently, edit `.gh-project.env` after setup.

**Slash commands** — Edit the `.claude/commands/*.md` files to match your conventions (branch naming, test commands, PR template, etc.).

**Auto-add issues** — In your GitHub Project settings → Workflows, enable "Auto-add items" so new issues are automatically added to the board.

## Updating

Re-run the install script to update `gh-project.sh`. Slash commands won't be overwritten if they already exist (in case you've customised them). Delete them first if you want a fresh copy.

## License

MIT
