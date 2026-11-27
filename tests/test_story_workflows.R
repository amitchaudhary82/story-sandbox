source("story_workflows.R")

expect_error <- function(expression) {
  inherits(try(expression, silent = TRUE), "try-error")
}

stopifnot(identical(validate_issue_numbers(c(1, 8)), c(1L, 8L)))
stopifnot(expect_error(validate_issue_numbers(c(1, 1))))
stopifnot(expect_error(validate_issue_numbers(c(0, 2))))
stopifnot(expect_error(validate_issue_numbers(c(1.5))))
stopifnot(identical(validate_labels(c("story", "in-review"), "add"),
                    c("story", "in-review")))
stopifnot(expect_error(validate_labels(c("story", "story"), "add")))
stopifnot(identical(require_non_empty_text("CAB-123", "cab_reference"),
                    "CAB-123"))
stopifnot(expect_error(require_non_empty_text("  ", "cab_reference")))
stopifnot(expect_error(update_labels(1, add = "ready", remove = "ready")))
stopifnot(expect_error(close_after_cab_approval(1, "", "Approval note")))

fetch_issue_page <- function(state, page) {
  if (page != 1L) {
    return(list())
  }
  list(
    list(
      number = 1L,
      title = "Example story",
      state = "open",
      labels = list(list(name = "story")),
      updated_at = "2026-11-22T09:00:00Z",
      pull_request = NULL
    ),
    list(
      number = 2L,
      title = "Example pull request",
      state = "open",
      labels = list(),
      updated_at = "2026-11-22T09:00:00Z",
      pull_request = list(url = "https://api.github.com/")
    )
  )
}

invisible(capture.output(stories <- list_stories()))
stopifnot(nrow(stories) == 1L)
stopifnot(stories$number[[1]] == 1L)
stopifnot(stories$labels[[1]] == "story")

selected_stories <- function(issue_numbers) {
  data.frame(
    number = issue_numbers,
    title = paste("Story", issue_numbers),
    state = "open"
  )
}
api_calls <- list()
github_request <- function(method, path, query = NULL, body = NULL) {
  api_calls[[length(api_calls) + 1L]] <<- list(
    method = method, path = path, query = query, body = body
  )
  invisible(NULL)
}
confirm_write <- function(action, stories, confirmation = "YES") FALSE

invisible(update_labels(1, add = "ready"))
invisible(post_story_comment(1, "Please review."))
invisible(close_after_cab_approval(1, "CAB-123", "Approved for closure."))
stopifnot(length(api_calls) == 0L)

confirm_write <- function(action, stories, confirmation = "YES") TRUE
invisible(close_after_cab_approval(1, "CAB-123", "Approved for closure."))
stopifnot(length(api_calls) == 2L)
stopifnot(api_calls[[1]]$method == "POST")
stopifnot(api_calls[[1]]$path == "issues/1/comments")
stopifnot(api_calls[[2]]$method == "PATCH")
stopifnot(api_calls[[2]]$body$state == "closed")

message("All local story workflow checks passed.")
