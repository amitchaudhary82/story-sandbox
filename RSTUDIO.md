# Use the story sandbox from RStudio

This guide is written for a first-time R user. The script uses R's `httr`
package to call GitHub's REST API directly. It does not run `gh` or shell
commands.

## 1. Open the project

In RStudio, choose **File → Open File** and open `story_workflows.R` from this
repository. Then choose **Session → Set Working Directory → To Source File
Location**. The Console should now be in the `story-sandbox` folder. You can
create an RStudio Project later if you want a convenient project shortcut.

## 2. Install the R packages

Run this once in the RStudio Console:

```r
install.packages(c("httr", "rstudioapi"))
```

These are the only packages the starter needs: `httr` makes HTTPS requests to
GitHub, and `rstudioapi` provides RStudio's masked password prompt.

## 3. Create a narrowly scoped GitHub token

Only do this if your workplace permits using a personal GitHub token on this
computer/network. This starter is configured for your personal sandbox, not
company repositories or company data. If policy or the office network blocks
it, ask your IT/security team rather than trying to work around the restriction.

On GitHub, create a **fine-grained personal access token** for your account:

1. Open **Settings → Developer settings → Personal access tokens → Fine-grained
   tokens** and create a token.
2. Select only the `story-sandbox` repository.
3. Grant **Issues: Read and write** repository permission. Do not grant broad
   account, organization, workflow, or repository permissions for this exercise.
4. Choose an expiration date. Copy the token once; GitHub will not show it again.

Never paste the token into chat, this repository, an R script, or a screenshot.
Do not put it in `README.md`, `SETUP.md`, or a committed `.Renviron` file.

## 4. Enter the token when prompted

When the script first needs to contact GitHub, RStudio opens a masked password
prompt. Paste your token there. It is not saved in Keychain, a file, or the
RStudio Environment pane. The script keeps it in a private in-memory function
environment for the current R session so it will not ask again for every
request.

When you finish, clear the cached token from the R session:

```r
clear_github_token()
```

Restarting R also clears the in-memory token. This reduces accidental exposure,
but is not a security boundary: code running in the same R session can still
access process memory. Do not source code you do not trust.

## 5. Try reading stories

Open `story_workflows.R`, click **Source**, then run:

```r
list_stories()
```

The default lists open stories. To include closed stories:

```r
list_stories(state = "all")
```

### What the R code sends to GitHub

The helper `github_request()` builds an HTTPS request to
`https://api.github.com/repos/amitchaudhary82/story-sandbox/...`, adds your
token and GitHub's API-version header, sends it with `httr::VERB()`, and checks
the HTTP response. The workflow functions use these GitHub API operations:

| R activity | HTTP method | GitHub API endpoint |
|---|---|---|
| List stories | `GET` | `/issues?state=open` |
| Add labels | `POST` | `/issues/{number}/labels` |
| Remove a label | `DELETE` | `/issues/{number}/labels/{name}` |
| Add a comment | `POST` | `/issues/{number}/comments` |
| Close a story | `PATCH` | `/issues/{number}` |

This makes the API request and response visible in ordinary R code, rather
than hiding them behind a command-line tool. The token grants access directly
to the configured personal sandbox; it does not make a blocked or unapproved
company API connection permissible. Follow your organization's policy and ask
IT if API access is blocked.

The script contains these write functions:

```r
update_labels(c(1, 2), add = "in-review", remove = "sprint-1")
post_story_comment(c(1, 2), "Please review the updated acceptance criteria.")
close_after_cab_approval(
  c(1),
  cab_reference = "CAB-123",
  comment = "Approved in the CAB meeting on 22 November."
)
```

Replace the example issue numbers, labels, and text with values from your
sandbox. Each write function shows which issues it will change and asks you to
type `YES`; the close function asks you to type `CLOSE`. Anything else cancels
the operation. For closing, you must also provide the CAB reference and an
approval note. The script cannot verify that CAB really approved something;
the operator is responsible for selecting the right stories and entering a
valid approval reference.

Bulk requests are sent one issue at a time. If GitHub reports an error partway
through, earlier issues may already have changed. Read the error, check the
affected stories in GitHub or with `list_stories(state = "all")`, and resume
only after confirming their current state.

## 6. Run the local checks

From the project directory, run:

```r
source("tests/test_story_workflows.R")
```

These checks do not contact GitHub or need a token.

## What this starter does not do

- It does not update GitHub Project board fields or iterations.
- It does not infer CAB approval from a label or comment; closure is a
  deliberate, manually selected action.
- It is for learning on the personal sandbox, not an unattended production
  workflow.
