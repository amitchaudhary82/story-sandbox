# MacBook workstation setup – Python, Git, GitHub

Personal learning setup for automating product-owner work
(GitHub stories and labels, later Squash exports and Word test evidence).

Started: 17 November 2026 · Last updated: 18 November 2026

---

## 1. Installed tools

| Tool | Version | How it was installed | What it is for |
|---|---|---|---|
| Homebrew | 7.0.14 | already installed | Package manager for the Mac Terminal |
| Python | 3.15.2 | `brew install python` | Programming language for scripts |
| pip | 26.2.2 | comes with Python | Installs Python libraries |
| git | 2.39.5 (Apple) | already installed (Xcode Command Line Tools) | Version control, sync with GitHub |
| gh (GitHub CLI) | 2.104.0 | `brew install gh` | GitHub from the Terminal: repos, issues, labels, boards |
| VS Code | 1.118.1 | already installed manually | Code editor, runs GitHub Copilot |

Check what is installed at any time (run in Terminal):

```bash
for tool in brew python3 pip3 git gh code; do
  if command -v $tool >/dev/null 2>&1; then
    printf "%-8s ✅  %s\n" "$tool" "$($tool --version 2>&1 | head -n 1)"
  else
    printf "%-8s ❌  not installed\n" "$tool"
  fi
done
```

## 2. Decisions and changes made

- **Anaconda switched off by default.** Old Anaconda Python 3.8 was active in every
  Terminal (`(base)` in the prompt). Turned off with
  `conda config --set auto_activate_base false`. Nothing was removed.
  Use it again with `conda activate base`; undo with the same command and `true`.
- **Homebrew Python is now the default** (`/opt/homebrew/...`).
- **VS Code `code` command** added via VS Code: Cmd+Shift+P →
  "Shell Command: Install 'code' command in PATH".
- **No container (DevPod, Dev Containers) for now.** Tools installed directly on the Mac;
  each project gets its own Python virtual environment (`.venv`) instead.
- **Personal GitHub account used**, not the company one.

## 3. Git and GitHub configuration

```bash
git config --global user.name "Amit Chaudhary"
git config --global user.email "38136186+amitchaudhary82@users.noreply.github.com"
gh auth login                 # GitHub.com → HTTPS → Yes → Login with a web browser
gh auth refresh -s project    # extra permission for project boards
gh auth status                # check login
```

- The **noreply email** is used because the GitHub email is set to private;
  GitHub can reject pushes that contain the private email.
- Login is stored in the macOS keychain. Token scopes: gist, project, read:org, repo, workflow.

## 4. Where things live

- **Repo folder on the Mac:** `/Users/amitchaudhary/Documents/GitHub/story-sandbox`
  (`~` = home folder `/Users/amitchaudhary`). All repos are kept in `~/Documents/GitHub`
  (the default folder of the GitHub Desktop app).
- **Repo on GitHub:** `amitchaudhary82/story-sandbox` (private)
- **Stories (issues), labels and the board live only on GitHub**, not in the folder.
  The folder holds files (README.md, SETUP.md, scripts); `gh` commands reach the rest.
- The hidden `.git` folder inside the repo is Git's own storage (history and the link to
  GitHub). Show hidden files in Finder with Cmd+Shift+. — never edit inside `.git`.

```bash
open ~/Documents/GitHub/story-sandbox                # open the folder in Finder
find ~ -maxdepth 4 -name .git -type d 2>/dev/null    # find all repos on the Mac
git remote -v                                        # which GitHub repo this folder is linked to
```

- The repo was first created in `~/dev` and then moved with
  `mv ~/dev/story-sandbox ~/Documents/GitHub/`. Moving a repo folder is safe:
  the GitHub link is stored in `.git` and moves with it.

## 5. Sandbox repo – how it was created

```bash
gh repo create story-sandbox --private --clone --add-readme
cd story-sandbox
gh label create story --color 1d76db --description "User story"
gh label create sprint-1 --color fbca04 --description "Planned for sprint 1"
gh issue create --title "Export test report" --body "As a PO I want to export the test report" --label story
gh issue create --title "User can log in" --body "As a user I want to log in so that I can see my data" --label story --label sprint-1
```

Current stories:

| # | Title | Labels |
|---|---|---|
| 1 | Export test report | story, sprint-1 |
| 2 | User can log in | story, in-review |

My own labels: `story`, `sprint-1`, `in-review`. The other 10 (`bug`, `enhancement`,
`question` …) are created automatically by GitHub in every new repo.

## 6. How gh commands are built

```
gh   <thing>   <action>   <which>   --details
gh   issue     view       2
gh   issue     edit       1         --add-label sprint-1
gh   label     create     in-review
```

- **thing:** `repo`, `issue`, `label`, `project`
- **action:** `list`, `view`, `create`, `edit`, `close`, `reopen`
- **which:** issue number or label name
- **details:** options starting with `--`; quotes only needed when a value has a space
- Stuck? Add `--help`: `gh issue --help`, `gh issue edit --help`

## 7. Commands I have used myself

```bash
gh issue list                                           # open stories
gh issue list --label sprint-1                          # filter by label
gh issue view 2                                         # one story in detail
gh issue edit 1 --add-label sprint-1                    # add a label
gh issue edit 2 --add-label in-review --remove-label sprint-1   # add and remove in one go
gh label create in-review                               # new label (random colour)
gh label list                                           # all labels in the repo
gh repo view --web                                      # open the repo in the browser
```

Reading `gh issue view` output: title, `owner/repo#number`, state (Open/Closed),
comments, labels, body text, link. Board status (Todo / In Progress / Done) is **not**
shown there – it belongs to the project board, not the issue.

## 8. Listing stories – `gh issue list` in detail

Full help: `gh issue list --help` (short alias: `gh issue ls`).

### Most useful flags

| Flag | Short | What it does | Example |
|---|---|---|---|
| `--state` | `-s` | open (default), closed or all | `gh issue list -s all` |
| `--label` | `-l` | only stories with this label; repeat = must have **all** | `gh issue list -l story -l sprint-1` |
| `--assignee` | `-a` | assigned to someone; `@me` = me | `gh issue list -a @me` |
| `--author` | `-A` | created by someone | `gh issue list -A amitchaudhary82` |
| `--milestone` | `-m` | in a milestone (e.g. a release) | `gh issue list -m "Release 1.0"` |
| `--search` | `-S` | GitHub search language (see below) | `gh issue list -S "no:label"` |
| `--limit` | `-L` | how many (default only **30**) | `gh issue list -L 200` |
| `--web` | `-w` | open the same list in the browser | `gh issue list -l story -w` |
| `--repo` | `-R` | another repo, without `cd` into it | `gh issue list -R owner/repo` |
| `--json` | | output raw data with chosen fields | `gh issue list --json number,title,labels` |
| `--jq` | `-q` | filter / reshape the JSON | see below |
| `--type` | | issue type (e.g. Bug, Epic) – organisation repos only | `gh issue list --type Bug` |

Watch out: without `-L`, only the first 30 stories are shown — on a real board use `-L 500`.

### Search language (`-S`) – same as the search box on github.com

```bash
gh issue list -S "label:story -label:in-review"     # story, but NOT in-review (minus = not)
gh issue list -S "no:label"                         # stories with no label at all
gh issue list -S "no:assignee"                      # nobody assigned
gh issue list -S "login in:title"                   # word "login" in the title
gh issue list -S "updated:<2026-11-01" -s open      # open and not touched since 1 Nov
gh issue list -S "sort:updated-asc"                 # oldest-updated first
gh issue list -s closed -S "closed:>2026-11-10"     # closed after 10 Nov
```

### JSON fields – getting data out for scripts

Available fields include: `number, title, state, labels, assignees, author, body,
createdAt, updatedAt, closedAt, milestone, comments, url, parent, subIssues,
subIssuesSummary, projectItems, blockedBy, blocking`.

```bash
# raw data
gh issue list --json number,title,state,labels

# one readable line per story: number, title, labels
gh issue list --json number,title,labels \
  --jq '.[] | "#\(.number)  \(.title)  [\([.labels[].name] | join(", "))]"'

# count stories per state
gh issue list -s all -L 500 --json state --jq 'group_by(.state) | map({state: .[0].state, count: length})'

# export to CSV – can be read in R with readr::read_csv("stories.csv")
echo "number,title,state,updated" > stories.csv
gh issue list -s all -L 500 --json number,title,state,updatedAt \
  --jq '.[] | [.number, .title, .state, .updatedAt] | @csv' >> stories.csv
```

Think of it like dplyr: `-l` / `-S` are `filter()`, `--json` fields are `select()`,
and `--jq` is a small `mutate()` / `summarise()` on the result.

## 9. Lessons learned

- **Paste one line at a time** when a command may ask a question (`brew install`,
  `gh auth login`). Otherwise the next lines are taken as answers ("Invalid input").
- After installing tools, **quit Terminal (Cmd+Q) and open a new window** so changes apply.
- Homebrew output is long; only the last lines matter. Look for `Error`.
- "It seems there is already an App" from Homebrew = app already installed by hand; harmless.
- **A label must exist before an issue can use it.** `gh issue create` and `gh issue edit`
  do not create labels – use `gh label create` first.
- **Check spelling:** `in.review` is not `in-review`; the error says "not found".
- **"Failed" can still mean part of the change happened** (the remove worked, the add
  failed). Always check with `gh issue view` after a change.
- Removing a label that is not on the issue is harmless.
- Habit: **change, then check.**

## 10. Saving this document to GitHub

```bash
cd ~/Documents/GitHub/story-sandbox
code SETUP.md                              # edit in VS Code, save with Cmd+S
git add SETUP.md                           # choose the file
git commit -m "Update setup documentation" # save a snapshot with a message
git push                                   # upload to GitHub
```

Every version is kept: on GitHub open SETUP.md → **History**.

## 11. Next steps

- [x] Install tools, configure Git, log in to GitHub
- [x] Create sandbox repo, labels and two stories
- [x] Move repo to `~/Documents/GitHub`
- [x] Exercises 1–3: view a story, add a label, create a label, add and remove labels
- [ ] Exercise 4: close story #1 and reopen it (hint: `gh issue --help`)
- [ ] Exercise 5: create the board, add stories, move cards Todo → In Progress → Done,
      create an epic with sub-issues, then check status from Terminal
- [ ] Update VS Code (Code → Check for Updates); install extensions Python,
      GitHub Copilot, GitHub Pull Requests and Issues
- [ ] Step 5: Python virtual environment in the repo (`python3 -m venv .venv`, `pip install requests`)
- [ ] Step 6: run `stories.py` to do the same label actions from Python
- [ ] Later: Squash export vs Word test evidence checker
