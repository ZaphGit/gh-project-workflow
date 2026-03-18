# gh-project-workflow

**GitHub Projects v2 + Claude Code integration.** Manage your backlog through a Kanban board, and let Claude Code autonomously pick up, work on, and deliver issues — all driven by slash commands.

> 🍴 Forked from [carlwestman/gh-project-workflow](https://github.com/carlwestman/gh-project-workflow) — extended with a web UI and additional tooling.

---

## How It Works

```
You prioritise issues in GitHub Projects (drag to reorder)
        │
        ▼
  /next-issue      → picks top Ready item, moves to In Progress, creates branch
  /update-progress → appends status updates to the issue
  /review-ready    → pushes, creates PR with Closes #N, moves to Review
        │
        ▼
  Merge PR to main → GitHub Action auto-moves issue to Done
```

The workflow turns your GitHub Project board into a simple task queue for Claude Code. You set priorities by dragging cards; Claude handles the rest.

---

## What Gets Installed

```
your-repo/
├── .claude/commands/
│   ├── next-issue.md            # Pick up next prioritised issue
│   ├── review-ready.md          # Submit work for review
│   ├── update-progress.md       # Update issue with progress notes
│   └── board.md                 # View board status
├── .github/workflows/
│   └── issue-done-on-merge.yml  # Auto-move issue to Done on PR merge
└── scripts/
    └── gh-project.sh            # CLI wrapper for GitHub Projects v2 GraphQL API
```

---

## Prerequisites

- [`gh` CLI](https://cli.github.com/) installed and authenticated
- [`jq`](https://jqlang.github.io/jq/) installed
- A [GitHub Project (v2)](https://docs.github.com/en/issues/planning-and-tracking-with-projects) linked to your repo
- Board columns named: **Backlog** → **Ready** → **In Progress** → **Review** → **Done**

### Install `gh` CLI

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
  && sudo apt update && sudo apt install gh -y
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

### Install `jq`

```bash
brew install jq          # macOS
sudo apt install jq -y   # Linux
winget install jqlang.jq # Windows
```

---

## Setup

### 1. Create a GitHub Project board

Repo → **Projects** → **New project** → **Board** layout.

Add/rename columns to: `Backlog`, `Ready`, `In Progress`, `Review`, `Done`.

### 2. Install the workflow

> ⚠️ **Security note:** Before running any `curl | bash` command, inspect the script first:
> ```bash
> curl -fsSL https://raw.githubusercontent.com/ZaphGit/gh-project-workflow/main/install.sh | less
> ```
> Once satisfied:
> ```bash
> curl -fsSL https://raw.githubusercontent.com/ZaphGit/gh-project-workflow/main/install.sh | bash
> ```

Or clone and run locally:
```bash
git clone https://github.com/ZaphGit/gh-project-workflow.git
cd your-project
../gh-project-workflow/install.sh
```

### 3. Connect to your project

```bash
./scripts/gh-project.sh setup
```

This auto-detects your repo, finds linked projects, maps column names to GraphQL IDs, and writes `.gh-project.env`.

> `.gh-project.env` is automatically added to `.gitignore` — do not commit it.

If you hit permission errors:
```bash
gh auth refresh -s project
```

### 4. Configure the GitHub Action variable

Repo → **Settings** → **Secrets and variables** → **Actions** → **Variables**:

| Variable | Value |
|---|---|
| `PROJECT_NUMBER` | Your project number (visible in the project URL) |

### 5. Add workflow docs to your CLAUDE.md

Append [`CLAUDE-PROJECT-WORKFLOW.md`](./CLAUDE-PROJECT-WORKFLOW.md) to your project's `CLAUDE.md` so Claude Code understands the workflow in every session.

---

## Usage

### Claude Code slash commands

| Command | What it does |
|---|---|
| `/next-issue` | Pick up top Ready issue, move to In Progress, create branch, start working |
| `/review-ready` | Run tests, push, create PR with `Closes #N`, move to Review |
| `/update-progress` | Append progress notes to current issue description |
| `/board` | Show all columns with item counts |

### CLI commands

```bash
./scripts/gh-project.sh next            # Show top Ready item
./scripts/gh-project.sh list-ready      # List all Ready items
./scripts/gh-project.sh list-in-progress
./scripts/gh-project.sh list "Review"   # List any column by name
./scripts/gh-project.sh move 42 "In Progress"
./scripts/gh-project.sh assign 42       # Assign issue to yourself
```

---

## Priority

Issue order in the **Ready** column determines what Claude picks up next. Drag cards to reorder. `/next-issue` always picks the top item.

---

## Customisation

- **Slash commands:** Edit `.claude/commands/*.md` to match your branch naming conventions, test commands, and PR templates.
- **Column names:** Edit `.gh-project.env` after setup if your columns are named differently.
- **Auto-add issues:** In GitHub Project settings → Workflows, enable "Auto-add items" so new issues appear on the board automatically.

---

## Updating

Re-run the install script to update `gh-project.sh`. Existing slash commands won't be overwritten (delete them first if you want a fresh copy).

---

## Roadmap

- [ ] **Web UI** — browser-based board view with drag-to-reprioritise, Claude Code trigger buttons, and live issue status
- [ ] **Multi-repo support** — manage issues across multiple repos from one board
- [ ] **Agent integration** — trigger AI agents directly from board cards

---

## Security Notes

- The install script uses `curl | bash` — inspect before running (see setup instructions above)
- `.gh-project.env` contains project config — keep it out of version control (handled by `.gitignore`)
- GitHub Actions workflow permissions should be scoped to minimum required (`projects: write`)
- Claude command files pass issue content into AI context — be aware of prompt injection risk in shared/public repos

---

## Credits

Originally created by [Carl Westman](https://github.com/carlwestman). Forked and extended by [ZaphGit](https://github.com/ZaphGit).

---

## License

MIT
